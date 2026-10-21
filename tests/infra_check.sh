#!/bin/bash
# Run after Terraform + Ansible (last stage of 02-config-ansible). Fails loudly on drift from the plan.
set -euo pipefail
R=${AWS_REGION:-us-east-1}; C=${CLUSTER:-shopnow-dev}
ACCOUNT=$(aws sts get-caller-identity --query Account --output text)

[ "$(aws eks describe-cluster --name "$C" --region "$R" --query cluster.status --output text)" = ACTIVE ] \
  && echo "PASS cluster $C ACTIVE"
READY=$(kubectl get nodes --no-headers | grep -c ' Ready ' || true)
[ "$READY" -ge 2 ] && echo "PASS $READY nodes Ready" || { echo "FAIL only $READY nodes Ready"; exit 1; }
kubectl -n kube-system rollout status deploy/coredns --timeout=60s >/dev/null && echo "PASS coredns"
kubectl top nodes >/dev/null && echo "PASS metrics-server (kubectl top works)"
kubectl -n monitoring get pods --no-headers | grep -v -E 'Running|Completed' && { echo "FAIL monitoring pods not running"; exit 1; } || echo "PASS monitoring pods running"
aws s3api get-bucket-versioning --bucket "shopnow-tfstate-$ACCOUNT" | grep -q Enabled && echo "PASS state bucket versioning"

# ---- cost guards
NAT=$(aws ec2 describe-nat-gateways --region "$R" --filter Name=state,Values=available --query 'NatGateways[].NatGatewayId' --output text)
[ -z "$NAT" ] && echo "PASS no NAT gateways" || { echo "COST GUARD FAIL: NAT gateway found: $NAT"; exit 1; }
LBS=$(aws elb describe-load-balancers --region "$R" --query 'length(LoadBalancerDescriptions)' --output text)
[ "$LBS" -le 1 ] && echo "PASS $LBS classic load balancer(s)" || { echo "COST GUARD FAIL: $LBS load balancers"; exit 1; }
echo "INFRA CHECK PASSED"
