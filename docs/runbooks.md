# Operational Runbooks

## 1. CI/CD Deployment Flow

1. Push to `main` or manually dispatch the workflow.
2. Monitor the `order-service-ci-cd` workflow in GitHub Actions.
3. Staging deployment completes automatically after tests and Docker push succeeds.
4. Validate the smoke test log in the workflow (`kubectl run order-service-smoke`).
5. Approve the `production` environment in GitHub once staging is healthy.
6. Confirm production rollout completes (`kubectl rollout status deployment/order-service-prod`).

### Required Secrets

| Secret                                       | Purpose                                             |
|----------------------------------------------|-----------------------------------------------------|
| `DOCKERHUB_USERNAME`, `DOCKERHUB_TOKEN`      | Push Docker images                                  |
| `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY` | IAM user with EKS, Route53 & Secrets Manager access |
| `ROUTE53_ZONE_ID`                            | Hosted zone ID used by Terraform/external-dns       |
| `TF_BACKEND_BUCKET`, `TF_BACKEND_DYNAMODB_TABLE` | Remote state storage and locking resources           |
| `EKS_ADMIN_ROLE_ARN_STAGING`, `EKS_ADMIN_ROLE_ARN_PROD` | IAM roles granted cluster-admin rights in each env |
| `ACM_CERTIFICATE_ARN`                        | Certificate ARN injected into Helm deploys          |

## 2. Manual Deployment (Fallback)

```bash
# Authenticate to AWS & configure kubectl
aws eks update-kubeconfig --region us-east-1 --name order-service-prod-eks

# Ensure Docker Hub secret exists for the namespace
kubectl create namespace prod --dry-run=client -o yaml | kubectl apply -f -
kubectl create secret docker-registry dockerhub-creds \
  --namespace prod \
  --docker-server=https://index.docker.io/v1/ \
  --docker-username=$DOCKERHUB_USERNAME \
  --docker-password=$DOCKERHUB_TOKEN \
  --dry-run=client -o yaml | kubectl apply -f -

# Deploy latest image tag
TAG=$(git rev-parse --short HEAD)
ACM_CERTIFICATE_ARN=$(terraform output -raw ingress_certificate_arn)
helm upgrade --install order-service-prod Infrastructure/helm \
  --namespace prod --create-namespace \
  -f Infrastructure/helm/values.prod.yaml \
  --set image.repository=chinthika/order-service \
  --set image.tag=$TAG \
  --set ingress.certificateArn=$ACM_CERTIFICATE_ARN
```

## 3. Smoke Testing

Verify the deployment internally after Helm upgrade:

```bash
kubectl run order-service-smoke --rm -n prod --restart=Never \
  --image=curlimages/curl:8.5.0 -- \
  curl --fail --retry 5 --retry-delay 5 http://order-service-prod.prod.svc.cluster.local:8000/health
```

External verification via ingress:

```bash
curl -fsSL https://prod.chinthika-jayani.click/health
```

## 4. Rollback Procedure

### Automated (via GitHub Actions)

If the production rollout fails, the `rollback-on-failure` job triggers automatically and reverts to the previous Helm revision.

### Manual (when automation is unavailable)

```bash
aws eks update-kubeconfig --region us-east-1 --name order-service-prod-eks
helm history order-service-prod --namespace prod
helm rollback order-service-prod <previous-revision> --namespace prod --cleanup-on-fail
kubectl rollout status deployment/order-service-prod -n prod --timeout=180s
```

## 5. Observability Checks

| Action           | Command                                                                                                                            |
|------------------|------------------------------------------------------------------------------------------------------------------------------------|
| NewRelic targets | `kubectl get servicemonitor -n monitoring order-service-prod`                                                                      |
| HPA status       | `kubectl get hpa -n prod order-service-prod`                                                                                       |

NewRelic alerts from kube-newrelic-stack can be tuned by overriding values in `Infrastructure/terraform/observability.tf`.

## 6. Secrets Rotation

1. Update the secret in AWS Secrets Manager (`order-service/prod`).
2. Restart or redeploy the deployment so pods pick up the new secret.
3. Update GitHub secrets if Docker Hub or Grafana credentials change.
4. Re-run Terraform apply if IRSA roles or alerting configuration is modified.

## 7. Terraform Operations

### GitHub Actions
- Trigger the `manage-infrastructure` workflow and choose the environment (`staging` / `production`) and action (`create` or `destroy`).
- Ensure the secrets `TF_BACKEND_BUCKET`, `TF_BACKEND_DYNAMODB_TABLE`, `ROUTE53_ZONE_ID`, `GRAFANA_ADMIN_PASSWORD`, `ACM_CERTIFICATE_ARN`, and AWS credentials are populated.
- Environment protection rules provide the manual approval step before Terraform applies changes.

### Local
- **Plan:** `terraform plan -out=tfplan.binary`
- **Apply:** `terraform apply tfplan.binary`
- **Destroy (non-production only):** `terraform destroy`