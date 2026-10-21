#!/bin/bash
# Minimal bootstrap: Java + Jenkins + Ansible. Everything else is installed by ansible/jenkins-host.yml.
set -eux
export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y fontconfig openjdk-21-jre-headless git unzip curl ansible python3-boto3 python3-botocore

# Jenkins LTS apt repo.
# VERIFY the key URL against https://www.jenkins.io/doc/book/installing/linux/#debianubuntu
# (Jenkins rotates its signing key; if apt complains about NO_PUBKEY, update this URL).
JENKINS_KEY_URL="https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key"
curl -fsSL "$JENKINS_KEY_URL" -o /usr/share/keyrings/jenkins-keyring.asc
echo "deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian-stable binary/" \
  > /etc/apt/sources.list.d/jenkins.list
apt-get update && apt-get install -y jenkins

# 2 GB swap: React builds on a 4 GB box need headroom
if [ ! -f /swapfile ]; then
  fallocate -l 2G /swapfile && chmod 600 /swapfile && mkswap /swapfile && swapon /swapfile
  echo '/swapfile none swap sw 0 0' >> /etc/fstab
fi
systemctl enable --now jenkins
