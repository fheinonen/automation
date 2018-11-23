# Set the variable value in *.tfvars file
# or using -var="hcloud_token=..." CLI option


# Configure the Hetzner Cloud Provider
provider "hcloud" {
  token = "${var.hcloud_token}"
}

# Configure AWS provider
provider "aws" {
   region = "${var.region}"
}

#  Main ssh key
data "hcloud_ssh_key" "ssh_key_1" {
  name = "Hetzner-key"
}
# Create 2 new streaming servers. 1 in Nuremberg and 1 in Falkenstein
resource "hcloud_server" "falkenstein" {
    name = "falkenstein"
    location = "fsn1"
    image = "${var.image}"
    server_type = "${var.server_type}"
    ssh_keys = ["${data.hcloud_ssh_key.ssh_key_1.id}"]
}
resource "hcloud_server" "nuremberg" {
    name = "nuremberg"
    location = "nbg1"
    image = "${var.image}"
    server_type = "${var.server_type}"
    ssh_keys = ["${data.hcloud_ssh_key.ssh_key_1.id}"]
}

# Create health checks
resource "aws_route53_health_check" "nuremberg_health" {
  ip_address        = "${hcloud_server.nuremberg.ipv4_address}"
  port              = 80
  type              = "HTTP"
  resource_path     = "/live/livestream.m3u8"
  failure_threshold = "3"
  request_interval  = "10"

  tags = {
    Name = "${hcloud_server.nuremberg.name}"
  }
}

resource "aws_route53_health_check" "falkenstein_health" {
  ip_address        = "${hcloud_server.falkenstein.ipv4_address}"
  port              = 80
  type              = "HTTP"
  resource_path     = "/live/livestream.m3u8"
  failure_threshold = "3"
  request_interval  = "10"

  tags = {
    Name = "${hcloud_server.falkenstein.name}"
  }
}

# Create A records for DNS weighting
resource "aws_route53_record" "tradefox_nuremberg" {
  zone_id = "your_zone_id"
  name    = "your_name"
  type    = "A"
  ttl     = "60"

  weighted_routing_policy {
    weight = 1
  }

  set_identifier = "${hcloud_server.nuremberg.name}"
  records        = ["${hcloud_server.nuremberg.ipv4_address}"]
  health_check_id = "${aws_route53_health_check.nuremberg_health.id}"
}
resource "aws_route53_record" "tradefox_falkenstein" {
  zone_id = "your_zone_id"
  name    = "your_name"
  type    = "A"
  ttl     = "60"

  weighted_routing_policy {
    weight = 1
  }

  set_identifier = "${hcloud_server.falkenstein.name}"
  records        = ["${hcloud_server.falkenstein.ipv4_address}"]
  health_check_id = "${aws_route53_health_check.falkenstein_health.id}"
}

# DNS records for pushing streams
resource "aws_route53_record" "nuremberg_push" {
  zone_id = "your_zone_id"
  name    = "your_name"
  type    = "A"
  ttl     = "60"
  records = ["${hcloud_server.nuremberg.ipv4_address}"]
}

resource "aws_route53_record" "falkenstein_push" {
  zone_id = "your_zone_id"
  name    = "your_name"
  type    = "A"
  ttl     = "60"
  records = ["${hcloud_server.falkenstein.ipv4_address}"]
}

# Create Alarms
resource "aws_cloudwatch_metric_alarm" "alarm_nuremberg" {
  alarm_name = "${hcloud_server.nuremberg.name}"
  alarm_actions = ["your_sns_topic"]
  comparison_operator = "LessThanThreshold"
  ok_actions = []
  evaluation_periods = "1"
  metric_name = "HealthCheckStatus"
  namespace = "AWS/Route53"
  period = "60"
  statistic = "Minimum"
  threshold = "1.0"
  evaluation_periods = "1"
  alarm_description = "This metric monitors streaming server nuremberg livestream"
  insufficient_data_actions = []
  actions_enabled = "true"
  dimensions = {
      HealthCheckId = "${aws_route53_health_check.nuremberg_health.id}"
    }
  }

  resource "aws_cloudwatch_metric_alarm" "alarm_falkenstein" {
  alarm_name = "${hcloud_server.falkenstein.name}"
  alarm_actions = ["your_sns_topic"]
  comparison_operator = "LessThanThreshold"
  ok_actions = []
  evaluation_periods = "1"
  metric_name = "HealthCheckStatus"
  namespace = "AWS/Route53"
  period = "60"
  statistic = "Minimum"
  threshold = "1.0"
  evaluation_periods = "1"
  alarm_description = "This metric monitors streaming server falkenstein livestream"
  insufficient_data_actions = []
  actions_enabled = "true"
  dimensions = {
      HealthCheckId = "${aws_route53_health_check.falkenstein_health.id}"
    }
  }
