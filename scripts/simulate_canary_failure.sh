#!/usr/bin/env bash
# Simulates a bad deploy so Argo Rollouts' Prometheus AnalysisTemplate
# catches it and auto-aborts the canary -- the portfolio-proof moment.
#
# Usage:
#   ./scripts/simulate_canary_failure.sh          # deploy the "bad" image
#   ./scripts/simulate_canary_failure.sh --watch  # + tail rollout status
set -euo pipefail

NAMESPACE="staging"
ROLLOUT="order-service"
BAD_IMAGE="ghcr.io/anirudhbabu/order-service:v2.1.0-fault-injected"

echo "==> Setting order-service image to a build that 500s on ~10% of requests"
kubectl argo rollouts set image "$ROLLOUT" \
  app="$BAD_IMAGE" \
  -n "$NAMESPACE"

echo "==> Argo Rollouts will now shift 10% traffic to the canary and start"
echo "    evaluating the success-rate + p99-latency AnalysisTemplate every 30s."
echo "    Expect an automatic abort within a few analysis cycles."

if [[ "${1:-}" == "--watch" ]]; then
  kubectl argo rollouts get rollout "$ROLLOUT" -n "$NAMESPACE" --watch
else
  echo "Run: kubectl argo rollouts get rollout $ROLLOUT -n $NAMESPACE --watch"
fi
