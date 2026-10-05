#!/usr/bin/env bash
set -euo pipefail

# Run this script ON the EC2 K3s server after Terraform creates the instance.
# Usage:
#   DOCKERHUB_USERNAME=yourname ./scripts/deploy-platform.sh

: "${DOCKERHUB_USERNAME:?Set DOCKERHUB_USERNAME before running this script}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

export KUBECONFIG="${KUBECONFIG:-/etc/rancher/k3s/k3s.yaml}"

kubectl get nodes

# Install/upgrade Prometheus + Grafana stack.
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

kubectl create namespace monitoring --dry-run=client -o yaml | kubectl apply -f -

helm upgrade --install kube-prometheus-stack \
  prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --values "${PROJECT_DIR}/monitoring/values.yaml" \
  --wait \
  --timeout 10m

# Deploy MyProfile.
mkdir -p /tmp/myprofile-deploy
sed "s#YOUR_DOCKERHUB_USERNAME#${DOCKERHUB_USERNAME}#g" \
  "${PROJECT_DIR}/k8s/deployment.yaml" > /tmp/myprofile-deploy/deployment.yaml

kubectl apply -f "${PROJECT_DIR}/k8s/namespace.yaml"
kubectl apply -f /tmp/myprofile-deploy/deployment.yaml
kubectl apply -f "${PROJECT_DIR}/k8s/service.yaml"
kubectl apply -f "${PROJECT_DIR}/k8s/ingress.yaml"

# Monitoring objects.
kubectl apply -f "${PROJECT_DIR}/monitoring/servicemonitor.yaml"
kubectl apply -f "${PROJECT_DIR}/monitoring/prometheus-rule.yaml"

kubectl -n myprofile rollout status deployment/myprofile --timeout=180s
kubectl -n myprofile get pods -o wide
kubectl -n myprofile get svc,ingress

echo
echo "MyProfile deployment completed."
echo "Open: http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)"
echo "Grafana is installed in namespace: monitoring"
