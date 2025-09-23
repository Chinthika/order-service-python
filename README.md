# Order Service Platform

A FastAPI microservice demonstrating end-to-end DevOps capabilities including automated testing, secure configuration, infrastructure-as-code for AWS EKS, observability with Prometheus/Grafana, and a GitHub Actions delivery pipeline.

## Repository Layout

```
order-service/
├── Infrastructure/
│   ├── Dockerfile                   # Container image definition
│   ├── helm/                        # Helm chart with staging/prod overlays
│   │   ├── Chart.yaml
│   │   ├── values.yaml
│   │   ├── values.staging.yaml
│   │   ├── values.prod.yaml
│   │   └── templates/
│   │       ├── _helpers.tpl
│   │       ├── deployment.yaml
│   │       ├── hpa.yaml
│   │       ├── ingress.yaml
│   │       ├── pdb.yaml
│   │       ├── service.yaml
│   │       ├── serviceaccount.yaml
│   │       └── servicemonitor.yaml
│   └── terraform/                   # Terraform to provision VPC, EKS & monitoring stack
│       ├── acm.tf
│       ├── alb_controller.tf
│       ├── eks.tf
│       ├── external_dns.tf
│       ├── locals.tf
│       ├── observability.tf
│       ├── outputs.tf
│       ├── providers.tf
│       ├── variables.tf
│       └── vpc.tf
├── src/
│   ├── app.py                       # FastAPI application with Prometheus instrumentation
│   ├── config/
│   │   ├── __init__.py
│   │   ├── secrets.py               # AWS Secrets Manager integration
│   │   └── settings.py              # Pydantic settings
│   ├── data/
│   ├── model/
│   ├── service/
│   └── utils.py
├── test/
│   ├── config/test_secrets.py
│   ├── service/test_order_service.py
│   └── test_app.py
├── .github/workflows/ci-cd.yaml     # GitHub Actions pipeline
├── docs/
│   ├── architecture.md
│   └── runbooks.md
├── dev-requirements.txt
├── requirements.txt
├── main.py
└── README.md
```

## Key Capabilities

- **FastAPI microservice** exposing order-management endpoints with unit and integration tests.
- **Configuration management** via Pydantic settings with optional AWS Secrets Manager integration.
- **Prometheus metrics** exposed on `/metrics` for scraping by kube-prometheus-stack.
- **Containerisation** using a lightweight Uvicorn-based Docker image.
- **Helm chart** supporting staging and production overlays, ServiceMonitor, HPA, PodDisruptionBudget, and IRSA-ready service accounts.
- **Terraform** provisioning VPC, EKS cluster, managed node group, kube-prometheus-stack, Prometheus adapter, and automated public ingress (ACM + ALB + Route53).
- **Public ingress** with AWS Load Balancer Controller, ACM-issued certificate, and Route53 automation via external-dns for `staging` and production hosts.
- **GitHub Actions CI/CD** pipeline covering linting, security scanning, tests, Terraform plan/apply, Docker build & push, staged deployments, manual promotion, smoke tests, and automated Helm rollback.

## Local Development

1. **Create a virtual environment**
   ```bash
   python -m venv .venv
   source .venv/bin/activate
   ```
2. **Install dependencies**
   ```bash
   pip install -r dev-requirements.txt
   ```
3. **Provide local configuration (optional)**
   Create a `.env` file to override defaults:
   ```env
   ENVIRONMENT=local
   LOG_LEVEL=DEBUG
   ENABLE_METRICS=true
   ```
4. **Run tests**
   ```bash
   pytest
   ```
5. **Launch the API**
   ```bash
   python main.py
   ```
   The service is available on `http://localhost:8000`, metrics on `http://localhost:8000/metrics`.

### Running via Docker

```bash
docker build -t order-service -f Infrastructure/Dockerfile .
docker run --rm -p 8000:8000 order-service
```

## Infrastructure as Code

Terraform provisions AWS networking, EKS, kube-prometheus-stack, Prometheus adapter, and public ingress components.

```bash
cd Infrastructure/terraform
terraform init
terraform plan \ \
  -var "grafana_admin_password=<password>" \
  -var "root_domain=chinthika-rathnayake.click" \
  -var "route53_zone_id=<hosted-zone-id>" \
  -var "prod_subdomain=@" \
  -var "staging_subdomain=staging"
terraform apply
```

> Provide `TF_VAR_root_domain`, `TF_VAR_route53_zone_id`, and subdomain variables (defaults: `@` for prod, `staging` for non-prod) to enable ACM certificate issuance and DNS automation.

The outputs include the EKS cluster name/endpoint and monitoring namespace used by the Helm chart.

## Helm Deployment

Deploy to an EKS cluster once credentials are configured:

```bash
helm upgrade --install order-service-staging Infrastructure/helm \
  --namespace staging --create-namespace \
  -f Infrastructure/helm/values.staging.yaml \
  --set image.repository=chinthika/order-service \
  --set image.tag=$(git rev-parse --short HEAD)
```

The chart exposes readiness/liveness probes, configures Prometheus scraping via ServiceMonitor, and creates an HPA driven by Prometheus adapter metrics.

## CI/CD Pipeline

The GitHub Actions workflow (`.github/workflows/ci-cd.yaml`) implements:

1. **Lint & Test:** `pytest`, `bandit`, and `pylint` against the FastAPI service.
2. **Terraform Plan:** Validates configuration and stores the plan artifact. Optional `terraform apply` is available on manual dispatch when `apply_infrastructure=true`.
3. **Build & Push:** Builds `Infrastructure/Dockerfile` and pushes tags (`latest` and `<sha>`) to Docker Hub.
4. **Staging Deploy:** Uses Helm to deploy to the staging namespace and runs a smoke test pod.
5. **Manual Promotion:** Requires approval via the GitHub Environment before production deployment.
6. **Production Deploy:** Helm upgrade to production with ACM certificate wiring, followed by rollout validation.
7. **Automated Rollback:** On production failure the workflow reverts to the previous Helm revision.

### Required GitHub Secrets

- `DOCKERHUB_USERNAME`, `DOCKERHUB_TOKEN`
- `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`
- `ROUTE53_ZONE_ID`
- `ACM_CERTIFICATE_ARN`
- `EKS_STAGING_CLUSTER_NAME`, `EKS_PROD_CLUSTER_NAME`
- `GRAFANA_ADMIN_PASSWORD`

## Observability

- `/metrics` endpoint exposes default FastAPI metrics through `prometheus-fastapi-instrumentator`.
- Helm chart creates a `ServiceMonitor` consumed by kube-prometheus-stack.
- Grafana dashboards become available via the chart with credential `admin`/`<grafana_admin_password>` set through Terraform.
- Configure Alertmanager rules in kube-prometheus-stack for alerting needs.

## Runbooks & Architecture

Detailed component diagrams, deployment flow, smoke tests, and rollback procedures are documented in:

- [`docs/architecture.md`](docs/architecture.md)
- [`docs/runbooks.md`](docs/runbooks.md)

These guides cover environment bootstrapping, CI/CD behavior, operational checks, and Helm rollback commands for production incidents.
