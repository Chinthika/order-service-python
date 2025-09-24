#!/usr/bin/env bash
#
# Manual cleanup utility for order-service infrastructure when Terraform state
# is unavailable. Deletes EKS, ACM, IAM, VPC, and Route53 resources that were
# previously created by Terraform for a specific environment.
#
# Usage:
#   chmod +x scripts/cleanup_environment.sh
#   AWS_PROFILE=my-profile AWS_REGION=us-east-1 ./scripts/cleanup_environment.sh staging
#   AWS_PROFILE=my-profile AWS_REGION=us-east-1 ./scripts/cleanup_environment.sh production
#
set -euo pipefail

ENVIRONMENT=${1:-}
REGION=${AWS_REGION:-us-east-1}
PROJECT="order-service"
ROOT_DOMAIN="chinthika-jayani.click"

if [[ -z "$ENVIRONMENT" ]]; then
  echo "Usage: $0 <staging|production>" >&2
  exit 1
fi

if [[ "$ENVIRONMENT" != "staging" && "$ENVIRONMENT" != "prod" ]]; then
  echo "Environment must be 'staging' or 'production'" >&2
  exit 1
fi

STACK_TAG="${PROJECT}-${ENVIRONMENT}"
CLUSTER_NAME="${PROJECT}-${ENVIRONMENT}-eks"
NODEGROUP_NAME="default"
VPC_TAG_FILTER="Name=tag:Project,Values=${PROJECT} Name=tag:Environment,Values=${ENVIRONMENT}"

########################################
# Helper functions
########################################

function log() {
  printf '\n[%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*"
}

function delete_acm_certificates() {
  log "Deleting ACM certificates for ${ENVIRONMENT}"
  local primary_domain prod_domain staging_domain
  if [[ "$ENVIRONMENT" == "production" ]]; then
    primary_domain="prod.${ROOT_DOMAIN}"
    prod_domain="prod.${ROOT_DOMAIN}"
    staging_domain=""
  else
    primary_domain="staging.${ROOT_DOMAIN}"
    prod_domain=""
    staging_domain="staging.${ROOT_DOMAIN}"
  fi

  local arns
  arns=$(aws acm list-certificates \
    --region "$REGION" \
    --query "CertificateSummaryList[?DomainName=='${primary_domain}' || DomainName=='${ROOT_DOMAIN}' || DomainName=='${prod_domain}' || DomainName=='${staging_domain}'].CertificateArn" \
    --output text)

  if [[ -z "$arns" ]]; then
    log "No ACM certificates found for ${ENVIRONMENT}."
  else
    for arn in $arns; do
      log "Deleting certificate $arn"
      aws acm delete-certificate --certificate-arn "$arn" --region "$REGION"
    done
  fi
}

function delete_route53_validation_records() {
  log "Deleting Route53 validation CNAMEs"
  local zone_id
  zone_id=$(aws route53 list-hosted-zones-by-name --dns-name "$ROOT_DOMAIN" --query 'HostedZones[0].Id' --output text)
  zone_id=${zone_id#/hostedzone/}

  local records=(
    "_prod.${ROOT_DOMAIN}"
    "_staging.${ROOT_DOMAIN}"
    "_${ROOT_DOMAIN}"
  )

  for record in "${records[@]}"; do
    local existing
    existing=$(aws route53 list-resource-record-sets --hosted-zone-id "$zone_id" --query "ResourceRecordSets[?contains(Name, '${record}') && Type=='CNAME']" --output json)
    if [[ "$existing" != "[]" ]]; then
      log "Deleting validation record containing ${record}"
      aws route53 change-resource-record-sets --hosted-zone-id "$zone_id" --change-batch "$(cat <<JSON
{
  "Changes": [
    {
      "Action": "DELETE",
      "ResourceRecordSet": ${existing:1:-1}
    }
  ]
}
JSON
)"
    fi
  done
}

function delete_nodegroup_and_cluster() {
  log "Deleting EKS nodegroup ${NODEGROUP_NAME} (if exists)"
  if aws eks describe-nodegroup --cluster-name "$CLUSTER_NAME" --nodegroup-name "$NODEGROUP_NAME" --region "$REGION" >/dev/null 2>&1; then
    aws eks delete-nodegroup --cluster-name "$CLUSTER_NAME" --nodegroup-name "$NODEGROUP_NAME" --region "$REGION"
    aws eks wait nodegroup-deleted --cluster-name "$CLUSTER_NAME" --nodegroup-name "$NODEGROUP_NAME" --region "$REGION"
  else
    log "Nodegroup ${NODEGROUP_NAME} not found"
  fi

  log "Deleting EKS cluster ${CLUSTER_NAME}"
  if aws eks describe-cluster --name "$CLUSTER_NAME" --region "$REGION" >/dev/null 2>&1; then
    aws eks delete-cluster --name "$CLUSTER_NAME" --region "$REGION"
    aws eks wait cluster-deleted --name "$CLUSTER_NAME" --region "$REGION"
  else
    log "Cluster ${CLUSTER_NAME} not found"
  fi
}

function delete_oidc_provider() {
  local issuer
  issuer=$(aws iam list-open-id-connect-providers --query "OpenIDConnectProviderList[?contains(Arn, '$CLUSTER_NAME')].Arn" --output text)
  if [[ -n "$issuer" ]]; then
    log "Deleting IAM OIDC provider $issuer"
    aws iam delete-open-id-connect-provider --open-id-connect-provider-arn "$issuer"
  else
    log "No OIDC provider matching $CLUSTER_NAME"
  fi
}

function delete_iam_roles_and_policies() {
  log "Deleting IAM roles/policies for ${ENVIRONMENT}"
  local roles
  roles=$(aws iam list-roles --query "Roles[?starts_with(RoleName, '${CLUSTER_NAME}') || starts_with(RoleName, '${CLUSTER_NAME%-eks}')].RoleName" --output text)
  for role in $roles; do
    local attachments
    attachments=$(aws iam list-attached-role-policies --role-name "$role" --query 'AttachedPolicies[].PolicyArn' --output text)
    for policy in $attachments; do
      log "Detaching $policy from $role"
      aws iam detach-role-policy --role-name "$role" --policy-arn "$policy"
    done

    log "Deleting inline policies for $role"
    inline=$(aws iam list-role-policies --role-name "$role" --query 'PolicyNames' --output text)
    for name in $inline; do
      aws iam delete-role-policy --role-name "$role" --policy-name "$name"
    done

    log "Deleting role $role"
    aws iam delete-role --role-name "$role"
  done

  local policies
  policies=$(aws iam list-policies --scope Local --query "Policies[?starts_with(PolicyName, '${CLUSTER_NAME}')].Arn" --output text)
  for policy in $policies; do
    log "Deleting policy $policy"
    aws iam delete-policy --policy-arn "$policy"
  done
}

function delete_cloudwatch_logs() {
  local log_group="/aws/eks/${CLUSTER_NAME}/cluster"
  if aws logs describe-log-groups --log-group-name-prefix "$log_group" --region "$REGION" --query 'logGroups' --output text | grep -q "$log_group"; then
    log "Deleting CloudWatch log group $log_group"
    aws logs delete-log-group --log-group-name "$log_group" --region "$REGION"
  fi
}

function delete_vpc_stack() {
  log "Deleting VPC and networking resources"
  local vpcs
  vpcs=$(aws ec2 describe-vpcs --filters ${VPC_TAG_FILTER} --query 'Vpcs[].VpcId' --output text)
  for vpc in $vpcs; do
    log "Tearing down VPC $vpc"

    # Delete load balancers associated with the VPC
    local lbs
    lbs=$(aws elbv2 describe-load-balancers --query 'LoadBalancers[?VpcId==`'"$vpc"'`].LoadBalancerArn' --output text)
    for lb in $lbs; do
      log "Deleting load balancer $lb"
      aws elbv2 delete-load-balancer --load-balancer-arn "$lb"
    done

    sleep 5

    # Delete NAT gateways
    local ngws
    ngws=$(aws ec2 describe-nat-gateways --filter "Name=vpc-id,Values=${vpc}" --query 'NatGateways[].NatGatewayId' --output text)
    for nat in $ngws; do
      log "Deleting NAT gateway $nat"
      aws ec2 delete-nat-gateway --nat-gateway-id "$nat"
    done

    # Release EIPs associated with NATs
    local eips
    eips=$(aws ec2 describe-addresses --filters "Name=tag:Project,Values=${PROJECT}" "Name=tag:Environment,Values=${ENVIRONMENT}" --query 'Addresses[].AllocationId' --output text)
    for eip in $eips; do
      log "Releasing EIP $eip"
      aws ec2 release-address --allocation-id "$eip"
    done

    # Detach and delete Internet Gateway
    local igw
    igw=$(aws ec2 describe-internet-gateways --filters "Name=attachment.vpc-id,Values=${vpc}" --query 'InternetGateways[0].InternetGatewayId' --output text)
    if [[ -n "$igw" ]]; then
      aws ec2 detach-internet-gateway --internet-gateway-id "$igw" --vpc-id "$vpc"
      aws ec2 delete-internet-gateway --internet-gateway-id "$igw"
    fi

    # Delete subnets
    local subnets
    subnets=$(aws ec2 describe-subnets --filters "Name=vpc-id,Values=${vpc}" --query 'Subnets[].SubnetId' --output text)
    for subnet in $subnets; do
      log "Deleting subnet $subnet"
      aws ec2 delete-subnet --subnet-id "$subnet"
    done

    # Delete route tables
    local rts
    rts=$(aws ec2 describe-route-tables --filters "Name=vpc-id,Values=${vpc}" --query 'RouteTables[?Associations[0].Main==`false`].RouteTableId' --output text)
    for rt in $rts; do
      log "Deleting route table $rt"
      aws ec2 delete-route-table --route-table-id "$rt"
    done

    # Delete security groups except default
    local sgs
    sgs=$(aws ec2 describe-security-groups --filters "Name=vpc-id,Values=${vpc}" --query 'SecurityGroups[?GroupName!=`default`].GroupId' --output text)
    for sg in $sgs; do
      log "Deleting security group $sg"
      aws ec2 delete-security-group --group-id "$sg"
    done

    log "Deleting VPC $vpc"
    aws ec2 delete-vpc --vpc-id "$vpc"
  done
}

########################################
# Execution
########################################

delete_acm_certificates
delete_route53_validation_records
delete_nodegroup_and_cluster
delete_oidc_provider
delete_iam_roles_and_policies
delete_cloudwatch_logs
delete_vpc_stack

log "Cleanup for ${ENVIRONMENT} complete"
