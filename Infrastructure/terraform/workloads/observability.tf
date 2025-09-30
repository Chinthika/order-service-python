resource "helm_release" "metrics_server" {
  count    = var.deploy_workloads ? 1 : 0
  provider = helm

  name       = "metrics-server"
  repository = "https://kubernetes-sigs.github.io/metrics-server/"
  chart      = "metrics-server"
  namespace  = "kube-system"

  timeout         = 600
  wait            = true
  atomic          = true
  cleanup_on_fail = true
  max_history     = 3

  # Ensure reliable connectivity to kubelets in EKS
  set {
    name  = "args[0]"
    value = "--kubelet-insecure-tls"
  }
  set {
    name  = "args[1]"
    value = "--kubelet-preferred-address-types=InternalIP\\,Hostname\\,ExternalIP"
  }
  set {
    name  = "apiService.insecureSkipTLSVerify"
    value = "true"
  }

  depends_on = [
    null_resource.wait_for_cluster
  ]
}

resource "helm_release" "newrelic" {
  count    = var.deploy_workloads ? 1 : 0
  provider = helm

  name             = "nri-bundle"
  repository       = "https://helm-charts.newrelic.com"
  chart            = "nri-bundle"
  namespace        = "newrelic"
  create_namespace = true
  version          = "6.0.14"

  timeout         = 1200
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

  set {
    name  = "metrics-adapter.enabled"
    value = "true"
  }

  set {
    name  = "newrelic-k8s-metrics-adapter.personalAPIKey"
    value = var.newrelic_api_key
  }

  set {
    name  = "newrelic-k8s-metrics-adapter.config.accountID"
    value = var.newrelic_account_id
  }

  set {
    name  = "newrelic-k8s-metrics-adapter.config.externalMetrics.requests_per_pod.query"
    value = "SELECT rate(count(*), 1 second) FROM Transaction WHERE appName = 'order-service-staging' SINCE 2 minutes ago"
    type  = "string"
  }

  set {
    name  = "newrelic-k8s-metrics-adapter.config.externalMetrics.requests_per_pod.removeClusterFilter"
    value = "true"
  }

  set {
    name  = "newrelic-k8s-metrics-adapter.config.externalMetrics.service_latency_p95.query"
    value = "SELECT percentile(duration,95) * 50000 FROM Transaction WHERE appName = 'order-service-prod' SINCE 2 minutes ago"
    type  = "string"
  }

  set {
    name  = "newrelic-k8s-metrics-adapter.config.externalMetrics.service_latency_p95.removeClusterFilter"
    value = "true"
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
    value = "false"
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
    helm_release.metrics_server,
    helm_release.aws_load_balancer_controller,
    null_resource.wait_for_cluster
  ]
}
