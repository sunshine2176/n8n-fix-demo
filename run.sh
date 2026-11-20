#!/usr/bin/env bash
# Start n8n for the demo and import the broken workflow fixture.
set -euo pipefail

docker start n8n-demo 2>/dev/null || docker run -d --name n8n-demo -p 5678:5678 -e N8N_SECURE_COOKIE=false n8nio/n8n

echo "waiting for n8n..."
until curl -sf http://localhost:5678/healthz > /dev/null; do sleep 1; done
echo "n8n ready: http://localhost:5678"
echo "login: n8n-demo@eikoro.com / N8nFixDemo!2026  (local demo account)"
echo ""
echo "Fire the webhook (expect HTTP 500 + TypeError):"
echo "  curl -X POST http://localhost:5678/webhook/order-sync -H 'Content-Type: application/json' -d @payload.json"
