variable "hcloud_token" {}
variable "image" {}
variable "server_type" {}
variable "region" {}
variable "hostname" {default = 
    ["test"]}
variable "server_count" {}
variable "location" {
    default = 
    ["nbg1", "fsn1"]
    }
variable "aws_access_key" {}

variable "aws_secret_key" {}

variable "A_record_TTL" {}

variable "domain" {}

variable "dns_zone_id" {}