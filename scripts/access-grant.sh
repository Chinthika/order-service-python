CLUSTER=order-service-shared-eks
PRINCIPAL=arn:aws:iam::494461918598:user/GitHubActions
REGION=us-east-1

aws eks associate-access-policy \
  --cluster-name "$CLUSTER" \
  --principal-arn arn:aws:iam::494461918598:user/GitHubActions \
  --policy-arn arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy \
  --access-scope type=cluster

aws eks associate-access-policy \
  --cluster-name "$CLUSTER" \
  --principal-arn arn:aws:iam::494461918598:root \
  --policy-arn arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy \
  --access-scope type=cluster


## Create an access entry for the IAM user
#aws eks create-access-entry \
#  --cluster-name "$CLUSTER" \
#  --principal-arn "$PRINCIPAL" \
#  --region "$REGION"
#
## Associate the AmazonEKSAdminPolicy (full cluster admin)
#aws eks associate-access-policy \
#  --cluster-name "$CLUSTER" \
#  --principal-arn "$PRINCIPAL" \
#  --policy-arn arn:aws:eks::aws:cluster-access-policy/AmazonEKSAdminPolicy \
#  --access-scope type=cluster \
#  --region "$REGION"
#
#aws eks describe-access-entry \
#  --cluster-name "$CLUSTER" \
#  --principal-arn "$PRINCIPAL" \
#  --region "$REGION"
## Look for associatedAccessPolicies -> AmazonEKSAdminPolicy (scope: cluster
#
#aws sts get-caller-identity         # confirm you’re using that IAM user (or role)
#aws eks update-kubeconfig --region us-east-1 --name order-service-staging-eks
#kubectl auth can-i '*' '*'
#kubectl auth can-i create customresourcedefinitions.apiextensions.k8s.io
#kubectl get nodes
#
#aws eks disassociate-access-policy \
#  --cluster-name order-service-staging-eks \
#  --principal-arn arn:aws:iam::494461918598:user/GitHubActions \
#  --policy-arn arn:aws:eks::aws:cluster-access-policy/AmazonEKSEditPolicy

#aws dynamodb delete-item \
#  --table-name "order-service-terraform-locks" \
#  --key "{\"LockID\":{\"S\":\"order-service-terraform-state/973899b1-ca71-3934-c515-9814a4dcd0fc\"}}"


# dynamo db delete all locks
#aws dynamodb delete-item --table-name "order-service-terraform-locks" --key "LockID=*"

#for lockid in $(aws dynamodb scan \
#  --table-name order-service-terraform-locks \
#  --query "Items[].LockID.S" \
#  --output text); do
#    aws dynamodb delete-item \
#      --table-name order-service-terraform-locks \
#      --key "{\"LockID\": {\"S\": \"$lockid\"}}"
#done

#aws service-quotas list-service-quotas \
#        --service-code es \
#        --quota-applied-at-level ALL >> es-quotas.json

#aws service-quotas request-service-quota-increase \
#        --service-code es \
#        --quota-code L-1216C47A \
#        --desired-value 30
#
#helm upgrade --install order-service-staging . --namespace staging \
#    --create-namespace \
#    -f values.staging.yaml \
#    --set image.tag=379c9fab \
#    --set image.repository=chinthika/order-service \
#    --set ingress.certificateArn=1234 \
#    --set autoscaling.newRelic.accountId=1234 \
#    --set autoscaling.newRelic.licenseKey=1234 --dry-run --debug

