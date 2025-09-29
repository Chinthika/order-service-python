variable "cluster_name" {
  type = string
}

variable "aws_region" {
  type = string
}

variable "common_tags" {
  type    = map(string)
  default = {}
}

variable "root_domain" {
  type = string
}

variable "route53_zone_id" {
  type = string
}

variable "deploy_workloads" {
  type    = bool
  default = true
}

variable "alb_controller_chart_version" {
  type    = string
  default = "1.8.2"
}

variable "external_dns_chart_version" {
  type    = string
  default = "1.15.1"
}

variable "newrelic_account_id" {
  type = string
}

variable "newrelic_api_key" {
  type = string
}

variable "newrelic_license_key" {
  type = string
}

variable "newrelic_region" {
  type = string
}
