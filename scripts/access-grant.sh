CLUSTER=order-service-staging-eks
PRINCIPAL=arn:aws:iam::494461918598:user/GitHubActions
REGION=us-east-1

#aws eks associate-access-policy \
#  --cluster-name "$CLUSTER" \
#  --principal-arn arn:aws:iam::494461918598:user/GitHubActions \
#  --policy-arn arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy \
#  --access-scope type=cluster

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
