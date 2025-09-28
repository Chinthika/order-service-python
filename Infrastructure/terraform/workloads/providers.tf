provider "aws" {
  region = var.aws_region
}

# Helm provider configured to talk to the existing EKS cluster using data sources from main.tf
provider "helm" {
  kubernetes {
    host                   = data.aws_eks_cluster.this.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.this.certificate_authority[0].data)
    token                  = data.aws_eks_cluster_auth.this.token
  }
}
