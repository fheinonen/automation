variable "hcloud_token" {}
variable "image" {}
variable "server_type" {}
variable "region" {}
variable "server_count" {}
variable "location" {
    default = 
    ["nbg1", "fsn1"]
    }
