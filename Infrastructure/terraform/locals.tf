locals {
  common_tags = {
    Project     = var.project
    Environment = var.environment
    ManagedBy   = "terraform"
  }

  cluster_name     = "${var.project}-${var.environment}-eks"
  prod_hostname    = var.prod_subdomain == "@" ? var.root_domain : "${var.prod_subdomain}.${var.root_domain}"
  staging_hostname = "${var.staging_subdomain}.${var.root_domain}"
}
