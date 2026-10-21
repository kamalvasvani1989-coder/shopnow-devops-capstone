#!/bin/bash
# Usage: bash tests/smoke.sh http://<load-balancer-dns>
set -euo pipefail
URL=${1:?usage: smoke.sh http://<lb-dns>}
echo "Waiting for $URL (a new load balancer's DNS takes 2-3 minutes)..."
for i in $(seq 1 30); do curl -sf "$URL/health" >/dev/null && break; sleep 10; done
curl -sf "$URL/health" | grep -q OK                      && echo "PASS frontend /health"
curl -sf "$URL/api/health" >/dev/null                    && echo "PASS backend /api/health via nginx proxy"
curl -sf "$URL/api/products" | jq -e . >/dev/null        && echo "PASS /api/products returns JSON"
curl -sf "$URL/" | grep -qi "<html"                      && echo "PASS storefront HTML served"
echo "SMOKE TEST PASSED"
