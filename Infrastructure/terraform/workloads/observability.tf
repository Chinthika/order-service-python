resource "aws_eks_addon" "metrics_server" {
  cluster_name = var.cluster_name
  addon_name   = "metrics-server"

  depends_on = [null_resource.wait_for_cluster]
}

resource "helm_release" "newrelic" {
  count    = var.deploy_workloads ? 1 : 0
  provider = helm

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
    value = "false"
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
    value = "false"
  }

  # Lower resource limits/requests for enabled New Relic components
  # kube-state-metrics
  set {
    name  = "kube-state-metrics.resources.requests.cpu"
    value = "50m"
  }
  set {
    name  = "kube-state-metrics.resources.requests.memory"
    value = "64Mi"
  }
  set {
    name  = "kube-state-metrics.resources.limits.cpu"
    value = "100m"
  }
  set {
    name  = "kube-state-metrics.resources.limits.memory"
    value = "128Mi"
  }

  # nri-metadata-injection
  set {
    name  = "nri-metadata-injection.resources.requests.cpu"
    value = "50m"
  }
  set {
    name  = "nri-metadata-injection.resources.requests.memory"
    value = "64Mi"
  }
  set {
    name  = "nri-metadata-injection.resources.limits.cpu"
    value = "100m"
  }
  set {
    name  = "nri-metadata-injection.resources.limits.memory"
    value = "128Mi"
  }

  depends_on = [
    aws_eks_addon.metrics_server,
    null_resource.wait_for_cluster
  ]
}

resource "helm_release" "keda" {
  count    = var.deploy_workloads ? 1 : 0
  provider = helm

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
    helm_release.newrelic
  ]
}
