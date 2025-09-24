module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.8"

  cluster_name    = local.cluster_name
  cluster_version = var.kubernetes_version

  cluster_endpoint_public_access  = true
  cluster_endpoint_private_access = false

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  enable_irsa = true

  tags = local.common_tags

  eks_managed_node_groups = {
    default = {
      min_size     = var.node_group_min_size
      max_size     = var.node_group_max_size
      desired_size = var.node_group_desired_size

      instance_types = var.node_instance_types
      capacity_type  = var.node_capacity_type

      subnet_ids = module.vpc.private_subnets

      tags = local.common_tags
    }
  }
}


resource "aws_eks_access_entry" "cluster_admin" {
  count        = var.eks_admin_role_arn == null ? 0 : 1
  cluster_name = module.eks.cluster_name

  principal_arn     = var.eks_admin_role_arn
  kubernetes_groups = ["system:masters"]
  type              = "STANDARD"
}


resource "aws_eks_access_policy_association" "cluster_admin" {
  count         = var.eks_admin_role_arn == null ? 0 : 1
  cluster_name  = module.eks.cluster_name
  principal_arn = var.eks_admin_role_arn
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"

  access_scope {
    type = "cluster"
  }

  depends_on = [aws_eks_access_entry.cluster_admin]
}
