#!/bin/bash
set -euo pipefail

# Validation script for k3s deployment
# Usage: ./validate.sh [environment]

ENVIRONMENT=${1:-production}

echo "🔍 Validating $ENVIRONMENT deployment..."

echo "📋 Checking namespaces..."
kubectl get namespaces | grep -E "(apps|cloudflared)" || echo "❌ Namespaces not found"

echo ""
echo "📦 Checking deployments..."
kubectl get deployments -A -l environment=$ENVIRONMENT

echo ""
echo "🎯 Checking services..."
kubectl get services -A -l environment=$ENVIRONMENT

echo ""
echo "🌐 Checking ingress..."
kubectl get ingress -A -l environment=$ENVIRONMENT

echo ""
echo "🔒 Checking pod security..."
for ns in apps cloudflared; do
  echo "Namespace: $ns"
  kubectl get pods -n $ns -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.spec.securityContext.runAsNonRoot}{"\n"}{end}' || true
done

echo ""
echo "💾 Checking persistent volumes..."
kubectl get pvc -A

echo ""
echo "🌡️  Checking resource usage..."
kubectl top nodes 2>/dev/null || echo "Metrics server not available"
kubectl top pods -A 2>/dev/null || echo "Metrics server not available"

echo ""
echo "🧪 Testing application endpoints..."
TRAEFIK_IP=$(kubectl get svc traefik -n kube-system -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "localhost")

if [ "$TRAEFIK_IP" != "localhost" ]; then
  echo "Testing whoami endpoint..."
  curl -s -H "Host: whoami.sotools.cc" "http://$TRAEFIK_IP" | head -5 || echo "❌ whoami endpoint failed"

  echo "Testing uptime endpoint..."
  curl -s -H "Host: uptime.sotools.cc" "http://$TRAEFIK_IP" | head -5 || echo "❌ uptime endpoint failed"
else
  echo "⚠️  Traefik load balancer IP not found, skipping endpoint tests"
fi

echo ""
echo "✅ Validation complete!"