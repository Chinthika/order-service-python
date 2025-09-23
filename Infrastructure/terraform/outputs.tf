output "cluster_name" {
  description = "EKS cluster name"
  value       = module.eks.cluster_name
}

output "cluster_endpoint" {
  description = "EKS API server endpoint"
  value       = module.eks.cluster_endpoint
}

output "prometheus_namespace" {
  description = "Namespace where Prometheus/Grafana are installed"
  value       = var.monitoring_namespace
}

output "grafana_admin_user" {
  description = "Grafana admin username"
  value       = "admin"
}

output "prod_hostname" {
  description = "Production hostname"
  value       = local.prod_hostname
}

output "staging_hostname" {
  description = "Staging hostname"
  value       = local.staging_hostname
}

output "ingress_certificate_arn" {
  description = "ARN of the ACM certificate for ingress"
  value       = aws_acm_certificate_validation.ingress.certificate_arn
}
