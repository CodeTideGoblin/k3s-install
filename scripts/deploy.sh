#!/bin/bash
set -euo pipefail

# Deployment script for k3s applications
# Usage: ./deploy.sh [environment] [component]

ENVIRONMENT=${1:-production}
COMPONENT=${2:-all}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"

echo "🚀 Deploying to $ENVIRONMENT environment..."

case $ENVIRONMENT in
  development|staging|production)
    OVERLAY_PATH="$REPO_ROOT/overlays/$ENVIRONMENT"
    if [ ! -d "$OVERLAY_PATH" ]; then
      echo "❌ Environment overlay not found: $OVERLAY_PATH"
      exit 1
    fi
    ;;
  *)
    echo "❌ Unknown environment: $ENVIRONMENT"
    echo "Available environments: development, staging, production"
    exit 1
    ;;
esac

case $COMPONENT in
  all)
    echo "📦 Deploying all components..."
    kubectl apply -k "$OVERLAY_PATH"
    ;;
  infrastructure)
    echo "🏗️  Deploying infrastructure..."
    kubectl apply -k "$REPO_ROOT/infrastructure"
    ;;
  apps)
    echo "📱 Deploying applications..."
    kubectl apply -k "$REPO_ROOT/apps"
    ;;
  metallb)
    echo "⚖️  Deploying MetalLB..."
    kubectl apply -k "$REPO_ROOT/infrastructure/overlays/metallb"
    ;;
  *)
    echo "❌ Unknown component: $COMPONENT"
    echo "Available components: all, infrastructure, apps, metallb"
    exit 1
    ;;
esac

echo "✅ Deployment complete!"
echo ""
echo "🔍 Checking deployment status..."
kubectl get pods -A -l environment=$ENVIRONMENT