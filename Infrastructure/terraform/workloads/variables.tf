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

variable "backend_bucket_name" {
  description = "Name of the S3 bucket used for backend state"
  type        = string
}

variable "backend_key_workloads" {
  description = "Path within the S3 bucket for the Terraform state file"
  type        = string
}

variable "backend_region" {
  description = "AWS region where the backend S3 bucket is located"
  type        = string
}

variable "backend_dynamodb_table" {
  description = "Name of the DynamoDB table for state locking"
  type        = string
}
