#!/usr/bin/env zsh
set -euo pipefail

CLUSTER_NAME="${1:-m1-lab}"
CLUSTER_CONFIG="./cluster.yml"
WORKLOAD_MANIFEST="./nginx.yml"
METRICS_SERVER_URL="https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml"

if [[ ! -f "$CLUSTER_CONFIG" ]]; then
  echo "Error: Cluster config '$CLUSTER_CONFIG' not found." >&2
  exit 1
fi

if [[ ! -f "$WORKLOAD_MANIFEST" ]]; then
  echo "Error: Workload manifest '$WORKLOAD_MANIFEST' not found." >&2
  exit 1
fi

if kind get clusters | grep -qx "$CLUSTER_NAME"; then
  echo "==> Cluster '$CLUSTER_NAME' already exists. Recreating cleanly..."
  kind delete cluster --name "$CLUSTER_NAME"
fi

echo "==> Creating kind cluster '$CLUSTER_NAME' using '$CLUSTER_CONFIG'..."
kind create cluster --name "$CLUSTER_NAME" --config "$CLUSTER_CONFIG"

kubectl config use-context "kind-${CLUSTER_NAME}" >/dev/null

echo "==> Waiting for nodes to be Ready..."
kubectl wait --for=condition=Ready nodes --all --timeout=120s

echo "==> Installing metrics-server..."
kubectl apply -f "$METRICS_SERVER_URL"

echo "==> Patching metrics-server with --kubelet-insecure-tls for kind..."
kubectl patch -n kube-system deployment metrics-server --type='json' \
  -p='[{"op":"add","path":"/spec/template/spec/containers/0/args/-","value":"--kubelet-insecure-tls"}]'

echo "==> Waiting for metrics-server rollout..."
kubectl rollout status -n kube-system deployment/metrics-server --timeout=120s

echo "==> Deploying workload manifest '$WORKLOAD_MANIFEST'..."
kubectl apply -f "$WORKLOAD_MANIFEST"

echo "==> Setting current namespace to 'sandbox'"
kubectl config set-context --current --namespace=sandbox

echo "==> Cluster ready. Current nodes and sandbox resources:"
kubectl get nodes -o wide
kubectl get pods,svc,hpa -n sandbox -o wide 2>/dev/null || kubectl get pods,svc,hpa -A