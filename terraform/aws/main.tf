module "net-sg" {
  source      = "terraform-aws-modules/security-group/aws"
  name        = "net-secgroup"
  description = "Defined port for access"
  vpc_id      = "vpc-0fd1f49f2c26b1ed4"
  ingress_with_cidr_blocks = [
    {
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      description = "SSH"
      cidr_blocks = "0.0.0.0/0"
    },
    {
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      description = "HTTP"
      cidr_blocks = "0.0.0.0/0"
    },
    {
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      description = "HTTPS"
      cidr_blocks = "0.0.0.0/0"
    }
  ]
}

module "nginx_asg_key" {
  source      = "terraform-aws-modules/key-pair/aws"
  key_name    = "nginx-asg-keypair"
  public_key  = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICGk7+ldhzxB3asdhBK1kwg5iBzf512BpwymIJLfJ9q6 hellonan@Hellonan"
}

module "asg" {
  source                    = "terraform-aws-modules/autoscaling/aws"
  name                      = "nginx-asg"
  min_size                  = 2
  max_size                  = 5
  desired_capacity          = 2
  health_check_type         = "EC2"
  vpc_zone_identifier       = ["subnet-0a6986e8c6eff425d"]
  security_groups           = ["sg-09e4bc4a961e1f5af"]
  key_name                  = "nginx-asg-keypair"  
  scaling_policies = {
    cpuPolicy = {
      policy_type               = "TargetTrackingScaling"
      target_tracking_configuration = {
        predefined_metric_specification = {
          predefined_metric_type = "ASGAverageCPUUtilization"
        }
        target_value = 45.0
      }
    }
  }

  instance_refresh = {
    strategy = "Rolling"
    preferences = {
      checkpoint_delay       = 600
      checkpoint_percentages = [35, 70, 100]
      instance_warmup        = 300
      min_healthy_percentage = 50
      max_healthy_percentage = 100
    }
    triggers = ["tag"]
  }

  # Launch template
  launch_template_name                = "nginx-asg-template"
  launch_template_description         = "Launch template example"
  update_default_version              = true
  image_id                            = "ami-08f49baa317796afd"
  instance_type                       = "t2.medium"
  ebs_optimized                       = true
  enable_monitoring                   = true
  create_iam_instance_profile         = true
  iam_role_name                       = "nginx-asg-template"
  iam_role_path                       = "/ec2/"
  iam_role_description                = "IAM role example"
  iam_role_tags = {
    CustomIamRole = "Yes"
  }
  iam_role_policies = {
    AmazonSSMManagedInstanceCore = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  }

  block_device_mappings = [
    {
      # Root volume
      device_name = "/dev/xvda"
      no_device   = 0
      ebs = {
        delete_on_termination = true
        encrypted             = true
        volume_size           = 40
        volume_type           = "gp3"
      }
    }
  ]

  # This will ensure imdsv2 is enabled, required, and a single hop which is aws security
  # best practices
  # See https://docs.aws.amazon.com/securityhub/latest/userguide/autoscaling-controls.html#autoscaling-4
  metadata_options = {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  placement = {
    availability_zone = "ap-southeast-1a"
  }

  tags = {
    Environment = "Experiments"
    Project     = "durianpay"
  }
}

module "cpu_metric_alarm" {
  source              = "terraform-aws-modules/cloudwatch/aws//modules/metric-alarm"
  version             = "~> 3.0"
  alarm_name          = "AlarmHighforCPU"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "120"
  statistic           = "Average"
  threshold           = "45"
  alarm_description   = "EC2 CPU Monitoring"
  dimensions = {
    AutoScalingGroupName = "nginx-asg-20241108074005082100000002"
  }
}

module "status_check_failed_metric_alarm" {
  source              = "terraform-aws-modules/cloudwatch/aws//modules/metric-alarm"
  version             = "~> 3.0"
  alarm_name          = "StatusCheckFailedAlarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "StatusCheckFailed"
  namespace           = "AWS/EC2"
  period              = "120"
  statistic           = "Sum"
  threshold           = "1"
  alarm_description   = "Failed status check Monitoring"
  dimensions = {
    AutoScalingGroupName = "nginx-asg-20241108074005082100000002"
  }
}

module "net_usage_alarm" {
  source              = "terraform-aws-modules/cloudwatch/aws//modules/metric-alarm"
  version             = "~> 3.0"
  alarm_name          = "NetUsageAlarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "NetworkIn"
  namespace           = "AWS/EC2"
  period              = "120"
  statistic           = "SampleCount"
  threshold           = "1000"
  alarm_description   = "High traffic income"
  dimensions = {
    AutoScalingGroupName = "nginx-asg-20241108074005082100000002"
  }
}