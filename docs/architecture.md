# Architecture Overview

```
┌────────────┐      ┌──────────────────────────┐      ┌─────────────────┐
│ GitHub Repo│ ───▶ │ GitHub Actions Workflow  │ ───▶ │ Docker Registry │
└────────────┘      └──────────────────────────┘      └─────────────────┘
        │                        │                              │
        │                        ▼                              │
        │               Terraform (AWS)                         │
        │                        │                              │
        ▼                        ▼                              ▼
 ┌────────────────┐     ┌────────────────┐          ┌────────────────────────┐
 │  AWS Networking│     │ AWS EKS (IRSA) │◀────────▶│ kube-prometheus-stack  │
 │  VPC + Subnets │     │  Managed nodes │          │ Prometheus + Grafana   │
 └────────────────┘     └────────────────┘          └────────────────────────┘
                                     │
                                     ▼
                            ┌────────────────┐
                            │ Order Service  │
                            │  FastAPI Pod   │
                            └────────────────┘
```

## Application Layer

- FastAPI application (`src/app.py`) exposes `/`, `/health`, `/orders`, and `/orders/{id}`.
- Configuration comes from environment variables managed by `src/config/settings.py`.
- AWS Secrets Manager integration (`src/config/secrets.py`) retrieves runtime secrets (e.g. database credentials) using IRSA-enabled service accounts.

## Container & Registry

- Docker image defined in `Infrastructure/Dockerfile` runs the app with Uvicorn/Gunicorn tooling.
- Built images are tagged as `chinthika/order-service:<sha>` by the GitHub Actions pipeline and pushed to Docker Hub.

## Kubernetes Deployment

- Helm chart under `Infrastructure/helm` configures:
  - ServiceAccount with IRSA annotation so pods can access Secrets Manager.
  - Deployment with staged values (`values.staging.yaml`, `values.prod.yaml`).
  - Health probes, resource requests/limits, and runtime environment variables.
  - Horizontal Pod Autoscaler (CPU & memory) and optional PodDisruptionBudget.
  - ServiceMonitor enabling Prometheus scraping and alerting.
  - Public ingress handled by AWS Load Balancer Controller with ACM TLS, with external-dns updating Route53 records.
- Staging and production namespaces receive the chart via the GitHub Actions pipeline.

## Infrastructure as Code

Terraform (`Infrastructure/terraform`) provisions AWS resources:

| Component | Description |
|-----------|-------------|
| `vpc.tf` | Dedicated VPC, public/private subnets, NAT gateway |
| `eks.tf` | EKS cluster (1.29) with managed node group and IRSA |
| `acm.tf` | Issues ACM certificates for root and staging domains, validated via Route53 |
| `alb_controller.tf` | Installs AWS Load Balancer Controller with IRSA permissions |
| `external_dns.tf` | Deploys external-dns for automatic Route53 record management |
| `observability.tf` | Installs kube-prometheus-stack and prometheus-adapter via Helm |
| `outputs.tf` | Provides cluster endpoint, monitoring namespace, Grafana admin username |

Variables accept environment identifiers, node sizing, chart versions, and secret inputs (Grafana credentials).

## Observability & Alerting

- Grafana dashboards (bundled with kube-prometheus-stack) provide application, pod, and cluster views.
- Prometheus Adapter exposes custom metrics to the Kubernetes HPA, enabling autoscaling based on CPU/memory.
- Alertmanager rules within kube-prometheus-stack can be configured for incident notification.

## CI/CD Pipeline

The GitHub Actions workflow orchestrates the following stages:

1. Linting, security scanning, and tests.
2. Terraform plan (and optional apply on manual dispatch).
3. Docker build & push using Buildx.
4. Helm deployment to staging with smoke tests.
5. Environment-gated promotion to production.
6. Automated Helm rollback when production deployment fails.

Secrets (Docker Hub, AWS, Grafana) are stored in GitHub Secrets. Environment protection rules ensure production requires manual approval.

## Configuration & Secrets

- Runtime configuration is environment-driven. Helm values set `ENVIRONMENT`, `AWS_REGION`, `AWS_SECRET_NAME`, and toggle Secrets Manager usage.
- Kubernetes ServiceAccount annotations bind pods to IAM roles for IRSA access to Secrets Manager.
- Sensitive values are injected via Kubernetes secrets (`envFromSecrets`) created by CI/CD or Terraform.
- `.env` can be used locally for non-production overrides.

## Data Flow Summary

1. Requests hit the AWS Application Load Balancer and reach the order-service pod.
2. Application serves JSON responses and records metrics (latency, throughput).
3. Prometheus scrapes metrics; Grafana dashboards visualise trends.
4. Prometheus adapter makes metrics available to the HPA for scaling decisions.
5. Alertmanager or external health checks built on Prometheus metrics raise incidents when thresholds are exceeded.
6. CI/CD pipeline rebuilds and redeploys the service on code changes, enforcing quality gates along the way.
