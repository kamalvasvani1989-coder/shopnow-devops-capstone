#!/bin/bash
# Run in AWS CloudShell after starting Jenkins (its public IP changes on every start).
# Usage: GH_PAT=<token with admin:repo_hook> bash scripts/update-webhook.sh <jenkins-instance-id> <owner/repo> <hook-id>
# Find the hook id once: curl -s -H "Authorization: Bearer $GH_PAT" https://api.github.com/repos/<owner/repo>/hooks | jq '.[].id'
set -euo pipefail
ID=${1:?jenkins instance id}; REPO=${2:?owner/repo}; HOOK=${3:?hook id}
: "${GH_PAT:?export GH_PAT first}"
aws ec2 wait instance-running --instance-ids "$ID"
IP=$(aws ec2 describe-instances --instance-ids "$ID" --query 'Reservations[0].Instances[0].PublicIpAddress' --output text)
curl -sf -X PATCH -H "Authorization: Bearer $GH_PAT" -H "Accept: application/vnd.github+json" \
  "https://api.github.com/repos/$REPO/hooks/$HOOK/config" \
  -d "{\"url\":\"http://$IP:8080/github-webhook/\",\"content_type\":\"json\"}" >/dev/null
echo "Webhook now points to http://$IP:8080/github-webhook/"
echo "Jenkins UI: http://$IP:8080"
