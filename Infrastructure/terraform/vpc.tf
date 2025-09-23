module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.1"

  name = "${var.project}-${var.environment}-vpc"
  cidr = var.vpc_cidr

  azs             = var.availability_zones
  private_subnets = var.private_subnets
  public_subnets  = var.public_subnets

  enable_nat_gateway            = true
  single_nat_gateway            = true
  enable_dns_hostnames          = true
  enable_dns_support            = true
  manage_default_security_group = true

  tags = local.common_tags
}
