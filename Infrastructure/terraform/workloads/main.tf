# EKS cluster details from AWS
data "aws_eks_cluster" "this" {
  name = var.cluster_name
}

data "aws_eks_cluster_auth" "this" {
  name = var.cluster_name
}

# Extra safety: wait until EKS is active before attempting any Kubernetes/Helm actions
resource "null_resource" "wait_for_cluster" {
  provisioner "local-exec" {
    command = "aws eks wait cluster-active --name ${var.cluster_name} --region ${var.aws_region}"
  }
}

# Helm provider configured to talk to the EKS cluster
provider "helm" {
  alias = "eks"
  kubernetes {
    host                   = data.aws_eks_cluster.this.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.this.certificate_authority[0].data)
    token                  = data.aws_eks_cluster_auth.this.token
  }
}