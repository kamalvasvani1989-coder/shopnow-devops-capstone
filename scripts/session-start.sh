#!/bin/bash
# Usage: bash scripts/session-start.sh <jenkins-instance-id>
set -euo pipefail
ID=${1:?jenkins instance id}
aws ec2 start-instances --instance-ids "$ID" >/dev/null
aws ec2 wait instance-running --instance-ids "$ID"
IP=$(aws ec2 describe-instances --instance-ids "$ID" --query 'Reservations[0].Instances[0].PublicIpAddress' --output text)
echo "Jenkins starting at http://$IP:8080 (give it ~1 minute)."
echo "Next: update the webhook (scripts/update-webhook.sh), then run 01-infra-terraform ACTION=apply ENV=dev."
echo "Post in team chat: 'Cluster going up, owner: <name>'"
