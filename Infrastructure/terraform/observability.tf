resource "aws_eks_addon" "metrics_server" {
  cluster_name = var.cluster_name
  addon_name   = "metrics-server"

  depends_on = [null_resource.wait_for_cluster]
}

resource "helm_release" "newrelic" {
  name             = "nri-bundle"
  repository       = "https://helm-charts.newrelic.com"
  chart            = "nri-bundle"
  namespace        = "newrelic"
  create_namespace = true
  version          = "5.0.84"

  timeout         = 900
  wait            = true
  atomic          = true
  cleanup_on_fail = true

  # Required
  set {
    name  = "global.licenseKey"
    value = var.newrelic_license_key
  }
  set {
    name  = "global.cluster"
    value = var.cluster_name
  }

  # Region (US/EU)
  set {
    name  = "global.region"
    value = var.newrelic_region
  }

  # Enable the core bits
  set {
    name  = "newrelic-infrastructure.enabled"
    value = "true"
  }
  set {
    name  = "kube-state-metrics.enabled"
    value = "true"
  }
  set {
    name  = "nri-metadata-injection.enabled"
    value = "true"
  }

  set {
    name  = "newrelic-logging.enabled"
    value = "true"
  }

  depends_on = [
    aws_eks_addon.metrics_server,
    null_resource.wait_for_cluster,
    aws_eks_access_entry.cluster_admin
  ]
}

resource "helm_release" "keda" {
  name             = "keda"
  repository       = "https://kedacore.github.io/charts"
  chart            = "keda"
  namespace        = "keda"
  create_namespace = true
  version          = "2.14.0"

  set {
    name  = "webhooks.cert.generate"
    value = "true"
  }

  depends_on = [
    null_resource.wait_for_cluster,
    helm_release.newrelic,
    aws_eks_access_entry.cluster_admin
  ]
}
