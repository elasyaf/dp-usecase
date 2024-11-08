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
  tags = {
    Terraform     = "true"
    Product       = "durianpay"
    Environment   = "technical-test"
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
  tags = {
    Terraform     = "true"
    Product       = "durianpay"
    Environment   = "technical-test"
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
  tags = {
    Terraform     = "true"
    Product       = "durianpay"
    Environment   = "technical-test"
  }
}