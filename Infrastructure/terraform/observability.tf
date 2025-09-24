resource "aws_eks_addon" "metrics_server" {
  cluster_name = var.cluster_name
  addon_name   = "metrics-server"

  depends_on = [module.eks, null_resource.wait_for_cluster]
}

# resource "helm_release" "newrelic" {
#   name             = "nri-bundle"
#   repository       = "https://helm-charts.newrelic.com"
#   chart            = "nri-bundle"
#   namespace        = "newrelic"
#   create_namespace = true
#   version          = "5.0.84"
#
#   timeout         = 900
#   wait            = true
#   atomic          = true
#   cleanup_on_fail = true
#
#   # Required
#   set {
#     name  = "global.licenseKey"
#     value = var.newrelic_license_key
#   }
#   set {
#     name  = "global.cluster"
#     value = var.cluster_name
#   }
#   set {
#     name  = "global.lowDataMode"
#     value = "true"
#   } # cheaper/smaller footprint
#
#   # Region (US/EU)
#   set {
#     name  = "global.nrStaging"
#     value = "false"
#   }
#   set {
#     name  = "global.region"
#     value = var.newrelic_region
#   }
#
#   # Enable the core bits
#   set {
#     name  = "newrelic-infrastructure.enabled"
#     value = "true"
#   }
#   set {
#     name  = "kube-state-metrics.enabled"
#     value = "true"
#   }
#   set {
#     name  = "nri-metadata-injection.enabled"
#     value = "true"
#   }
#
#   # Logs (optional: disable to keep it lean)
#   set {
#     name  = "newrelic-logging.enabled"
#     value = "false"
#   }
#
#   # Resource limits
#   set {
#     name  = "newrelic-infrastructure.resources.requests.cpu"
#     value = "50m"
#   }
#   set {
#     name  = "newrelic-infrastructure.resources.requests.memory"
#     value = "100Mi"
#   }
#   set {
#     name  = "newrelic-infrastructure.resources.limits.cpu"
#     value = "200m"
#   }
#   set {
#     name  = "newrelic-infrastructure.resources.limits.memory"
#     value = "200Mi"
#   }
#
#   set {
#     name  = "kube-state-metrics.resources.requests.cpu"
#     value = "50m"
#   }
#   set {
#     name  = "kube-state-metrics.resources.requests.memory"
#     value = "100Mi"
#   }
#   set {
#     name  = "kube-state-metrics.resources.limits.cpu"
#     value = "200m"
#   }
#   set {
#     name  = "kube-state-metrics.resources.limits.memory"
#     value = "200Mi"
#   }
#
#   set {
#     name  = "nri-kubernetes.resources.requests.cpu"
#     value = "50m"
#   }
#   set {
#     name  = "nri-kubernetes.resources.requests.memory"
#     value = "100Mi"
#   }
#   set {
#     name  = "nri-kubernetes.resources.limits.cpu"
#     value = "200m"
#   }
#   set {
#     name  = "nri-kubernetes.resources.limits.memory"
#     value = "200Mi"
#   }
#
#   depends_on = [
#     module.eks,
#     aws_eks_addon.metrics_server,
#     null_resource.wait_for_cluster
#   ]
# }
#
# resource "helm_release" "keda" {
#   name             = "keda"
#   repository       = "https://kedacore.github.io/charts"
#   chart            = "keda"
#   namespace        = "keda"
#   create_namespace = true
#   version          = "2.14.0"
#
#   set {
#     name  = "webhooks.cert.generate"
#     value = "true"
#   }
#
#   set {
#     name  = "operator.resources.requests.cpu"
#     value = "50m"
#   }
#   set {
#     name  = "operator.resources.requests.memory"
#     value = "64Mi"
#   }
#   set {
#     name  = "operator.resources.limits.cpu"
#     value = "200m"
#   }
#   set {
#     name  = "operator.resources.limits.memory"
#     value = "128Mi"
#   }
#
#   set {
#     name  = "metricsServer.resources.requests.cpu"
#     value = "20m"
#   }
#   set {
#     name  = "metricsServer.resources.requests.memory"
#     value = "64Mi"
#   }
#   set {
#     name  = "metricsServer.resources.limits.cpu"
#     value = "100m"
#   }
#   set {
#     name  = "metricsServer.resources.limits.memory"
#     value = "128Mi"
#   }
#
#   depends_on = [module.eks]
# }
