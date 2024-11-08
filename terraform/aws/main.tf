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
  egress_with_cidr_blocks = [
    {
      from_port       = 0
      to_port         = 0
      protocol        = "-1"
      description     = "Allow All Outbound Traffic"
      cidr_blocks     = "0.0.0.0/0"
    }
  ]
}

module "asg" {
  source                    = "terraform-aws-modules/autoscaling/aws"
  name                      = "nginx-asg"
  desired_capacity          = 2
  min_size                  = 2
  max_size                  = 5
  health_check_type         = "EC2"
  vpc_zone_identifier       = ["subnet-0a6986e8c6eff425d"]
  security_groups           = ["sg-09e4bc4a961e1f5af"]  
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
    AmazonSSMManagedInstanceCore        = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore",
    AmazonEC2ContainerRegistryPullOnly  = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryPullOnly"
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

  network_interfaces = [
    {
      delete_on_termination = true
      description           = "eth0"
      device_index          = 0
      security_groups       = ["sg-09e4bc4a961e1f5af"]
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
    Terraform     = "true"
    Product       = "durianpay"
    Environment   = "technical-test"
  }
  user_data = <<-EOT
IyEvYmluL2Jhc2gKCnN1ZG8gc3UKeXVtIHVwZGF0ZSAteQp5dW0gaW5zdGFsbCAt
eSB5dW0tdXRpbHMgZGV2aWNlLW1hcHBlci1wZXJzaXN0ZW50LWRhdGEgbHZtMgp5
dW0gaW5zdGFsbCAteSB5dW0tdXRpbHMgZGV2aWNlLW1hcHBlci1wZXJzaXN0ZW50
LWRhdGEgbHZtMgp5dW0gaW5zdGFsbCBkb2NrZXIgLXkKc3lzdGVtY3RsIGVuYWJs
ZSBkb2NrZXIKc3lzdGVtY3RsIHN0YXJ0IGRvY2tlcgphd3MgZWNyIGdldC1sb2dp
bi1wYXNzd29yZCAtLXJlZ2lvbiBhcC1zb3V0aGVhc3QtMSB8IGRvY2tlciBsb2dp
biAtLXVzZXJuYW1lIEFXUyAtLXBhc3N3b3JkLXN0ZGluIDUzNjY5NzI2MDQ2Mi5k
a3IuZWNyLmFwLXNvdXRoZWFzdC0xLmFtYXpvbmF3cy5jb20KZG9ja2VyIHJ1biAt
ZCAtLW5hbWUgd2Vic2VydmVyIC1wIDgwOjgwODAgNTM2Njk3MjYwNDYyLmRrci5l
Y3IuYXAtc291dGhlYXN0LTEuYW1hem9uYXdzLmNvbS9kcC93ZWJzZXJ2ZXI6bGF0
ZXN0Cg==
  EOT
}