# EKS cluster details from AWS
data "aws_eks_cluster" "this" {
  name = var.cluster_name
}

data "aws_eks_cluster_auth" "this" {
  name = var.cluster_name
}

data "aws_caller_identity" "current" {}

data "aws_partition" "current" {}

locals {
  cluster_oidc_issuer_url = data.aws_eks_cluster.this.identity[0].oidc[0].issuer
  oidc_provider_arn       = "arn:${data.aws_partition.current.partition}:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/${replace(local.cluster_oidc_issuer_url, "https://", "")}"
}

# Extra safety: wait until EKS is active before attempting any Kubernetes/Helm actions
resource "null_resource" "wait_for_cluster" {
  provisioner "local-exec" {
    command = "aws eks wait cluster-active --name ${var.cluster_name} --region ${var.aws_region}"
  }
}