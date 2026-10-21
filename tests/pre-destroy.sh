#!/bin/bash
# Removes AWS resources that Kubernetes created (load balancers, volumes). Terraform does not
# know about them and they block VPC deletion. Called by 01-infra-terraform before destroy.
set -e
C=${1:-shopnow-dev}; R=${AWS_REGION:-us-east-1}
aws eks describe-cluster --name "$C" --region "$R" >/dev/null 2>&1 || { echo "cluster $C not found - nothing to clean"; exit 0; }
aws eks update-kubeconfig --name "$C" --region "$R"
kubectl get svc -A -o json | jq -r '.items[] | select(.spec.type=="LoadBalancer") | "\(.metadata.namespace) \(.metadata.name)"' |
  while read -r ns name; do echo "deleting LoadBalancer service $ns/$name"; kubectl delete svc -n "$ns" "$name"; done
kubectl delete pvc --all -A --wait=false || true
echo "waiting 90s for AWS to remove the load balancer and its security group..."
sleep 90
