terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }

    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.13"
    }
  }
}


provider "aws" {
  region = var.aws_region
}


module "workloads" {
  count  = var.deploy_workloads ? 1 : 0
  source = "./workloads"

  # Cluster and environment inputs
  cluster_name = module.eks.cluster_name
  aws_region   = var.aws_region
  common_tags  = local.common_tags

  # EKS OIDC details required for IRSA
  oidc_provider_arn       = module.eks.oidc_provider_arn
  cluster_oidc_issuer_url = module.eks.cluster_oidc_issuer_url

  # Networking / DNS
  vpc_id          = module.vpc.vpc_id
  root_domain     = var.root_domain
  route53_zone_id = var.route53_zone_id

  # Workloads toggles and versions
  deploy_workloads             = var.deploy_workloads
  alb_controller_chart_version = var.alb_controller_chart_version
  external_dns_chart_version   = var.external_dns_chart_version

  # Observability
  newrelic_account_id  = var.newrelic_account_id
  newrelic_license_key = var.newrelic_license_key
  newrelic_region      = var.newrelic_region
}
