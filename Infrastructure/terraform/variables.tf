variable "project" {
  type        = string
  description = "Short name for the workload used when naming AWS resources"
  default     = "order-service"
}

variable "environment" {
  type        = string
  description = "Deployment environment identifier"
  default     = "prod"
}

variable "aws_region" {
  type        = string
  description = "AWS region for infrastructure deployment"
  default     = "us-east-1"
}

variable "aws_profile" {
  type        = string
  description = "Optional AWS named profile for authentication"
  default     = null
}

variable "vpc_cidr" {
  type        = string
  description = "CIDR range for the VPC"
  default     = "10.10.0.0/16"
}

variable "availability_zones" {
  type        = list(string)
  description = "List of availability zones to spread the subnets across"
  default     = ["us-east-1a", "us-east-1b"]
}

variable "private_subnets" {
  type        = list(string)
  description = "CIDR ranges for private subnets hosting workloads"
  default     = ["10.10.1.0/24", "10.10.2.0/24"]
}

variable "public_subnets" {
  type        = list(string)
  description = "CIDR ranges for public subnets hosting ingress components"
  default     = ["10.10.101.0/24", "10.10.102.0/24"]
}

variable "kubernetes_version" {
  type        = string
  description = "EKS control plane Kubernetes version"
  default     = "1.29"
}

variable "node_group_min_size" {
  type        = number
  description = "Minimum number of worker nodes"
  default     = 1
}

variable "node_group_max_size" {
  type        = number
  description = "Maximum number of worker nodes"
  default     = 2
}

variable "node_group_desired_size" {
  type        = number
  description = "Desired number of worker nodes"
  default     = 1
}

variable "node_instance_types" {
  type        = list(string)
  description = "EC2 instance types backing the managed node group"
  default     = ["t3.micro"]
}

variable "node_capacity_type" {
  type        = string
  description = "Capacity type for the node group (e.g. ON_DEMAND or SPOT)"
  default     = "ON_DEMAND"
}

variable "monitoring_namespace" {
  type        = string
  description = "Namespace into which monitoring components are installed"
  default     = "monitoring"
}

variable "grafana_admin_password" {
  type        = string
  description = "Initial Grafana admin password"
  sensitive   = true
}

variable "prometheus_retention" {
  type        = string
  description = "Retention period for Prometheus metrics"
  default     = "7d"
}

variable "prometheus_scrape_interval" {
  type        = string
  description = "Default Prometheus scrape interval"
  default     = "30s"
}

variable "kube_prometheus_stack_version" {
  type        = string
  description = "Version of the kube-prometheus-stack Helm chart"
  default     = "65.5.0"
}

variable "prometheus_adapter_version" {
  type        = string
  description = "Version of the prometheus-adapter Helm chart"
  default     = "4.10.0"
}

variable "root_domain" {
  type        = string
  description = "Registered root domain (e.g. chinthika-jayani.click)"
}

variable "staging_subdomain" {
  type        = string
  description = "Subdomain prefix for staging environment"
  default     = "staging"
}

variable "prod_subdomain" {
  type        = string
  description = "Subdomain (or '@' for root) used for production"
  default     = "@"
}

variable "route53_zone_id" {
  type        = string
  description = "Route53 hosted zone ID managing the root domain"
}

variable "alb_controller_chart_version" {
  type        = string
  description = "AWS Load Balancer Controller Helm chart version"
  default     = "1.8.2"
}

variable "external_dns_chart_version" {
  type        = string
  description = "external-dns Helm chart version"
  default     = "1.15.1"
}
