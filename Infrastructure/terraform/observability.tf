resource "helm_release" "kube_prometheus_stack" {
  name       = "kube-prometheus"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
  version    = var.kube_prometheus_stack_version

  namespace        = var.monitoring_namespace
  create_namespace = true

  values = [
    yamlencode({
      grafana = {
        adminUser     = "admin"
        adminPassword = var.grafana_admin_password
        persistence = {
          enabled = false
        }
        sidecar = {
          dashboards = {
            enabled         = true
            searchNamespace = "ALL"
          }
        }
      }

      prometheus = {
        prometheusSpec = {
          retention      = var.prometheus_retention
          scrapeInterval = var.prometheus_scrape_interval
        }
      }

      alertmanager = {
        alertmanagerSpec = {
          replicas = 2
        }
      }
    })
  ]

  depends_on = [
    module.eks,
    null_resource.wait_for_cluster
  ]
}


resource "helm_release" "prometheus_adapter" {
  name       = "prometheus-adapter"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "prometheus-adapter"
  version    = var.prometheus_adapter_version

  namespace = var.monitoring_namespace

  values = [
    yamlencode({
      prometheus = {
        url = format("http://kube-prometheus-kube-prometheus.%s.svc:9090", var.monitoring_namespace)
      }

      rules = {
        default = true
      }
    })
  ]

  depends_on = [
    module.eks,
    null_resource.wait_for_cluster,
    helm_release.kube_prometheus_stack
  ]
}
