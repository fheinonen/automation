# Configure the Hetzner Cloud Provider
provider "hcloud" {
  token = var.hcloud_id
}

data "hcloud_ssh_key" "ssh_key_1" {
  name = "Hetzner-key"
}

# Configure AWS provider
provider "aws" {
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
  region     = var.region
}

# Create new streaming server(s)
resource "hcloud_server" "video" {
  count       = var.server_count
  name        = "${element(var.hostname, count.index)}${count.index + 1}"
  location    = element(var.location, count.index)
  image       = var.image
  server_type = var.server_type
  ssh_keys    = [data.hcloud_ssh_key.ssh_key_1.id]
}

# Create reverse DNS

resource "hcloud_rdns" "tradefox_rdns" {
  count     = var.server_count
  server_id = element(hcloud_server.video.*.id, count.index)
  ip_address = element(hcloud_server.video.*.ipv4_address, count.index)
  dns_ptr = var.domain
}
# Create multianswer A record(s) for server(s)
resource "aws_route53_record" "tradefox" {
  count                            = var.server_count
  zone_id                          = var.dns_zone_id
  name                             = var.domain
  type                             = "A"
  ttl                              = var.A_record_TTL
  multivalue_answer_routing_policy = "true"

  set_identifier  = "${element(var.hostname, count.index)}${count.index + 1}"
  records         = [element(hcloud_server.video.*.ipv4_address, count.index)]
  health_check_id = element(aws_route53_health_check.health_check.*.id, count.index)
}

# # Create multianswer AAAA record(s) for server(s)
resource "aws_route53_record" "tradefoxv6" {
  count                            = var.server_count
  zone_id                          = var.dns_zone_id
  name                             = var.domain
  type                             = "AAAA"
  ttl                              = var.A_record_TTL
  multivalue_answer_routing_policy = "true"

  set_identifier  = "${element(var.hostname, count.index)}${count.index + 1}V6"
  records         = ["${element(hcloud_server.video.*.ipv6_address, count.index)}1"]
  health_check_id = element(aws_route53_health_check.health_check.*.id, count.index)
}

# Create unique A record(s) for server(s)
resource "aws_route53_record" "push" {
  count   = var.server_count
  zone_id = var.dns_zone_id
  name    = "${element(var.hostname, count.index)}${count.index + 1}.tradefox.biz."
  type    = "A"
  ttl     = var.A_record_TTL
  records = [element(hcloud_server.video.*.ipv4_address, count.index)]
}

# Create unique AAAA record(s) for server(s)
resource "aws_route53_record" "pushv6" {
  count   = var.server_count
  zone_id = var.dns_zone_id
  name    = "${element(var.hostname, count.index)}${count.index + 1}.tradefox.biz."
  type    = "AAAA"
  ttl     = var.A_record_TTL
  records = ["${element(hcloud_server.video.*.ipv6_address, count.index)}1"]
}

# Create health check(s)
resource "aws_route53_health_check" "health_check" {
  count             = var.server_count
  ip_address        = element(hcloud_server.video.*.ipv4_address, count.index)
  port              = 80
  type              = "HTTP"
  resource_path     = var.stream_path
  failure_threshold = "3"
  request_interval  = "10"
  tags = {
    Name = "HealthCheck-${element(var.hostname, count.index)}${count.index + 1}"
  }
}

# Create alarm(s) for server(s)
resource "aws_cloudwatch_metric_alarm" "alarm" {
  count                     = var.server_count
  alarm_name                = "Alarm-${element(var.hostname, count.index)}${count.index + 1}"
  alarm_actions             = ["arn:aws:sns:us-east-1:991445153020:Nuremberg1_is_down"]
  comparison_operator       = "LessThanThreshold"
  ok_actions                = []
  evaluation_periods        = "1"
  metric_name               = "HealthCheckStatus"
  namespace                 = "AWS/Route53"
  period                    = "60"
  statistic                 = "Minimum"
  threshold                 = "1.0"
  alarm_description         = "This metric monitors streaming server ${element(var.hostname, count.index)}${count.index + 1} livestream"
  insufficient_data_actions = []
  actions_enabled           = "true"
  dimensions = {
    HealthCheckId = element(aws_route53_health_check.health_check.*.id, count.index)
  }
}

