#!/bin/bash
# Run after 01-infra-terraform ACTION=destroy. Everything below should be empty except Jenkins.
R=${AWS_REGION:-ap-southeast-2}
echo "== EKS clusters (expect none)";            aws eks list-clusters --region $R --query clusters --output text
echo "== Classic LBs (expect none)";             aws elb describe-load-balancers --region $R --query 'LoadBalancerDescriptions[].LoadBalancerName' --output text
echo "== ALB/NLBs (expect none)";                aws elbv2 describe-load-balancers --region $R --query 'LoadBalancers[].LoadBalancerName' --output text
echo "== NAT gateways (expect none)";            aws ec2 describe-nat-gateways --region $R --filter Name=state,Values=available --query 'NatGateways[].NatGatewayId' --output text
echo "== Unattached EBS volumes (expect none)";  aws ec2 describe-volumes --region $R --filters Name=status,Values=available --query 'Volumes[].VolumeId' --output text
echo "== Unassociated Elastic IPs (expect none)"; aws ec2 describe-addresses --region $R --query 'Addresses[?AssociationId==null].PublicIp' --output text
echo "== Running instances (expect only shopnow-jenkins, and stop it next)"
aws ec2 describe-instances --region $R --filters Name=instance-state-name,Values=running \
  --query 'Reservations[].Instances[].[InstanceId, Tags[?Key==`Name`]|[0].Value]' --output text
echo
echo "Stop Jenkins: aws ec2 stop-instances --instance-ids <jenkins-id>   then post 'Cluster down at HH:MM'"
