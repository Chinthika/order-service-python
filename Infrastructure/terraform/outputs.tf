output "cluster_name" {
  description = "EKS cluster name"
  value       = module.eks.cluster_name
}

output "cluster_endpoint" {
  description = "EKS API server endpoint"
  value       = module.eks.cluster_endpoint
}

output "prod_hostname" {
  description = "Production hostname"
  value       = local.prod_hostname
}

output "staging_hostname" {
  description = "Staging hostname"
  value       = local.staging_hostname
}



output "ingress_certificate_arns" {
  description = "Map of ACM certificate ARNs for ingress, keyed by environment (staging/prod)"
  value       = { for k, v in aws_acm_certificate_validation.ingress : k => v.certificate_arn }
}
