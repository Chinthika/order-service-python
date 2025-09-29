# Order Service Platform

A FastAPI microservice demonstrating end-to-end DevOps capabilities including automated testing, secure configuration, infrastructure-as-code for AWS EKS, observability with New Relic, and a GitHub Actions delivery pipeline.

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
│   │       └── serviceaccount.yaml
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
- **Containerisation** using a lightweight Uvicorn-based Docker image.
- **Helm chart** supporting staging and production overlays, HPA, PodDisruptionBudget, and IRSA-ready service accounts.
- **Terraform** provisioning VPC, EKS cluster, managed node group, and automated public ingress (ACM + ALB + Route53). Observability agents (New Relic) are installed via the workloads module.
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
   The service is available on `http://localhost:8000`.

### Running via Docker

```bash
docker build -t order-service -f Infrastructure/Dockerfile .
docker run --rm -p 8000:8000 order-service
```

## Infrastructure as Code

Terraform provisions AWS networking, EKS, and public ingress components. Observability is handled by New Relic agents installed via the workloads module.

Two-module workflow: run Terraform separately for the EKS cluster and for the workloads.

1) Cluster — create VPC and EKS only
```bash
cd Infrastructure/terraform
terraform init
terraform plan -out=tfplan.cluster
terraform apply tfplan.cluster
```

Optionally grant your IAM role temporary admin access if needed:
```bash
./scripts/access-grant.sh
```

2) Workloads — install controllers and addons
```bash
cd Infrastructure/terraform/workloads
terraform init
terraform plan -out=tfplan.workloads \
  -var "cluster_name=<your-cluster-name>" \
  -var "aws_region=us-east-1" \
  -var "root_domain=chinthika-jayani.click" \
  -var "route53_zone_id=<route53-zone-id>" \
  -var "newrelic_license_key=<nr-license>" \
  -var "newrelic_account_id=<nr-account>"
terraform apply tfplan.workloads
```

> Provide `TF_VAR_root_domain`, `TF_VAR_route53_zone_id`, and subdomain variables (e.g. `prod` and `staging`) to enable
> ACM certificate issuance and DNS automation.

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

The chart exposes readiness/liveness probes and creates an HPA driven by built-in Kubernetes CPU/memory metrics. Prometheus/ServiceMonitor are no longer required; telemetry is shipped by New Relic agents.

## CI/CD Pipeline

The GitHub Actions workflow (`.github/workflows/ci-cd.yaml`) implements:

1. **Lint & Test:** `pytest`, `bandit`, and `pylint` against the FastAPI service.
2. **Build & Push:** Builds `Infrastructure/Dockerfile` and pushes tags (`latest` and `<sha>`) to Docker Hub.
3. **Staging Deploy:** Uses Helm to deploy to the staging namespace and runs a smoke test pod.
4. **Manual Promotion:** Requires approval via the GitHub Environment before production deployment.
5. **Production Deploy:** Helm upgrade to production with ACM certificate wiring, followed by rollout validation.
6. **Automated Rollback:** On production failure the workflow reverts to the previous Helm revision.

Note on rollback behavior: Helm upgrades use `--atomic`, which automatically rolls back a failed install/upgrade. The separate rollback step in the workflow exists to handle failures detected after Helm returns success (e.g., rollout health checks). It is optional—safe to keep for extra protection, or remove if you prefer to rely solely on `--atomic`. 

### Required GitHub Secrets

- `DOCKERHUB_USERNAME`, `DOCKERHUB_TOKEN`
- `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`
- `ROUTE53_ZONE_ID`
- `TF_BACKEND_BUCKET`, `TF_BACKEND_DYNAMODB_TABLE`
- `EKS_ADMIN_ROLE_ARN_STAGING`, `EKS_ADMIN_ROLE_ARN_PROD`
- `ACM_CERTIFICATE_ARN`
- `NEW_RELIC_LICENSE_KEY`, `NEW_RELIC_ACCOUNT_ID`

### Notes

- Provide `ACM_CERTIFICATE_ARN` secret after running Terraform so deployments can inject the certificate.
- Deployments target a single shared EKS cluster: `order-service-shared-eks`, with separate Kubernetes namespaces `staging` and `prod`.
- Define environment-specific IAM administration roles and store their ARNs in `EKS_ADMIN_ROLE_ARN_STAGING` and
  `EKS_ADMIN_ROLE_ARN_PROD` so the workflow can grant Kubernetes `system:masters` access automatically.
- Terraform defaults to a single `t3.micro` managed node (min 1, max 2) to stay within the AWS free tier; adjust the
  node variables if you require additional capacity.

## Observability

- We use New Relic for cluster and application telemetry. The Terraform workloads module installs the New Relic `nri-bundle` (kube-state-metrics, metadata injection, etc.). Provide `NEW_RELIC_LICENSE_KEY` and `NEW_RELIC_ACCOUNT_ID`.
- Dashboards, querying, and alerting should be configured in New Relic.

## Runbooks & Architecture

Detailed component diagrams, deployment flow, smoke tests, and rollback procedures are documented in:

- [`docs/architecture.md`](docs/architecture.md)
- [`docs/runbooks.md`](docs/runbooks.md)

These guides cover environment bootstrapping, CI/CD behavior, operational checks, and Helm rollback commands for production incidents.

## Infrastructure Workflow

Use `.github/workflows/infra-manage.yaml` to provision or tear down AWS resources. Trigger the workflow manually and choose:

- `environment`: `staging` or `production`
- `action`: `create` (runs plan, waits for environment approval, then applies) or `destroy`

The job uses the remote S3 backend (`TF_BACKEND_BUCKET` / `TF_BACKEND_DYNAMODB_TABLE`) and the same Terraform code as local runs. Configure GitHub environment protections to require approval before production changes.

