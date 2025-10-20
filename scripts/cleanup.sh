#!/bin/bash
set -euo pipefail

# Cleanup script for k3s deployment
# Usage: ./cleanup.sh [environment] [--force]

ENVIRONMENT=${1:-production}
FORCE=${2:-}

echo "🧹 Cleaning up $ENVIRONMENT deployment..."

if [ "$FORCE" != "--force" ]; then
    echo "⚠️  This will delete all resources in the $ENVIRONMENT environment."
    echo "Are you sure? Use --force flag to skip this confirmation."
    read -p "Continue? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "❌ Cleanup cancelled."
        exit 1
    fi
fi

case $ENVIRONMENT in
  development|staging|production)
    OVERLAY_PATH="overlays/$ENVIRONMENT"
    if [ -d "$OVERLAY_PATH" ]; then
      echo "🗑️  Deleting $ENVIRONMENT resources..."
      kubectl delete -k "$OVERLAY_PATH" --ignore-not-found=true
    fi
    ;;
  all)
    echo "🗑️  Deleting all environments..."
    for env in development staging production; do
      echo "Deleting $env..."
      kubectl delete -k "overlays/$env" --ignore-not-found=true || true
    done
    ;;
  *)
    echo "❌ Unknown environment: $ENVIRONMENT"
    echo "Available environments: development, staging, production, all"
    exit 1
    ;;
esac

echo "🧽 Cleaning up infrastructure..."
kubectl delete -k infrastructure/base --ignore-not-found=true || true

echo "✅ Cleanup complete!"
echo ""
echo "📝 Remaining resources:"
kubectl get all -A