# Operational Runbooks

## 1. CI/CD Deployment Flow

1. Push to `main` or manually dispatch the workflow.
2. Monitor the `order-service-ci-cd` workflow in GitHub Actions.
3. Staging deployment completes automatically after tests and Docker push succeed.
4. Validate the smoke test log in the workflow (`kubectl run order-service-smoke`).
5. Approve the `production` environment in GitHub once staging is healthy.
6. Confirm production rollout completes (`kubectl rollout status deployment/order-service-prod`).

### Required Secrets

| Secret                                       | Purpose                                             |
|----------------------------------------------|-----------------------------------------------------|
| `DOCKERHUB_USERNAME`, `DOCKERHUB_TOKEN`      | Push Docker images                                  |
| `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY` | IAM user with EKS, Route53 & Secrets Manager access |
| `ROUTE53_ZONE_ID`                            | Hosted zone ID used by Terraform/external-dns       |
| `ACM_CERTIFICATE_ARN`                        | Certificate ARN injected into Helm deploys          |
| `GRAFANA_ADMIN_PASSWORD`                     | Injected into Terraform for kube-prometheus-stack   |

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

| Action             | Command                                                                                                                            |
|--------------------|------------------------------------------------------------------------------------------------------------------------------------|
| Prometheus targets | `kubectl get servicemonitor -n monitoring order-service-prod`                                                                      |
| Verify metrics     | `curl -fsSL https://prod.chinthika-jayani.click/metrics                                                                            | head` |
| Grafana access     | Port-forward `kubectl port-forward svc/kube-prometheus-grafana -n monitoring 3000:80` and login (`admin/<grafana_admin_password>`) |
| HPA status         | `kubectl get hpa -n prod order-service-prod`                                                                                       |

Prometheus alerts from kube-prometheus-stack can be tuned by overriding values in `Infrastructure/terraform/observability.tf`.

## 6. Secrets Rotation

1. Update the secret in AWS Secrets Manager (`order-service/prod`).
2. Restart or redeploy the deployment so pods pick up the new secret.
3. Update GitHub secrets if Docker Hub or Grafana credentials change.
4. Re-run Terraform apply if IRSA roles or alerting configuration is modified.

## 7. Terraform Operations

- **Plan:** `terraform plan -out=tfplan.binary`
- **Apply:** `terraform apply tfplan.binary`
- **Destroy (non-production only):** `terraform destroy`

Always provide the required variables (e.g. `grafana_admin_password`). Use a remote backend for shared state in collaborative environments.

## 8. Incident Response Checklist

1. Inspect GitHub Actions logs for deployment failures and review `kubectl rollout` output.
2. Check Prometheus/Grafana alerts for error details.
3. If necessary, trigger manual rollback (Section 4).
4. Validate service health (`/health`, `/metrics`) after recovery.
5. Create a post-incident ticket summarising the root cause and resolution.
