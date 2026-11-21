#!/usr/bin/env zsh
set -euo pipefail

CLUSTER_NAME="${1:-m1-lab}"

if ! command -v kind >/dev/null 2>&1; then
  echo "Error: 'kind' is not installed or not in PATH." >&2
  exit 1
fi

if kind get clusters 2>/dev/null | grep -qx "$CLUSTER_NAME"; then
  echo "==> Deleting kind cluster '$CLUSTER_NAME'..."
  kind delete clusters "$CLUSTER_NAME"
else
  echo "==> Cluster '$CLUSTER_NAME' not found. Nothing to delete."
fi

echo "==> Remaining kind clusters:"
kind get clusters || true

if command -v docker >/dev/null 2>&1; then
  echo "==> Running containers matching '${CLUSTER_NAME}-':"
  docker ps --filter "name=${CLUSTER_NAME}-" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" || true
fi