#!/bin/bash
set -euo pipefail

# Setup script for Cloudflare Tunnel
# Usage: ./setup-cloudflared.sh [tunnel-name] [domain]

TUNNEL_NAME=${1:-my-tunnel}
DOMAIN=${2:-sotools.cc}

echo "🌐 Setting up Cloudflare Tunnel..."
echo "Tunnel name: $TUNNEL_NAME"
echo "Domain: $DOMAIN"

# Check if cloudflared is installed
if ! command -v cloudflared &> /dev/null; then
    echo "📦 Installing cloudflared..."
    curl -fsSL https://pkg.cloudflare.com/cloudflare-main.gpg | sudo tee /usr/share/keyrings/cloudflare-main.gpg >/dev/null
    echo "deb [signed-by=/usr/share/keyrings/cloudflare-main.gpg] https://pkg.cloudflare.com/cloudflared $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/cloudflared.list
    sudo apt update && sudo apt install -y cloudflared
fi

# Login to Cloudflare
echo "🔐 Logging in to Cloudflare..."
cloudflared tunnel login

# Create tunnel
echo "🚇 Creating tunnel..."
cloudflared tunnel create "$TUNNEL_NAME"

# Get tunnel ID
TUNNEL_ID=$(cloudflared tunnel list | grep "$TUNNEL_NAME" | awk '{print $1}')
echo "Tunnel ID: $TUNNEL_ID"

# Create namespace if it doesn't exist
echo "📋 Creating namespace..."
kubectl create namespace cloudflared || true

# Create secret with tunnel credentials
echo "🔑 Creating secret..."
kubectl -n cloudflared create secret generic tunnel-credentials \
    --from-file=credentials.json="$HOME/.cloudflared/$TUNNEL_ID.json" \
    --dry-run=client -o yaml | kubectl apply -f -

# Update configmap with tunnel name
echo "⚙️  Updating configuration..."
kubectl -n cloudflared create configmap cloudflared \
    --from-literal=config.yaml="
tunnel: $TUNNEL_NAME
credentials-file: /etc/cloudflared/creds/credentials.json
metrics: 0.0.0.0:2000
no-autoupdate: true
ingress:
- hostname: \"*.$DOMAIN\"
  service: http://traefik.kube-system.svc.cluster.local:80
- service: http_status:404
" --dry-run=client -o yaml | kubectl apply -f -

# Setup DNS routes
echo "🌍 Setting up DNS routes..."
cloudflared tunnel route dns "$TUNNEL_NAME" "*.$DOMAIN"
cloudflared tunnel route dns "$TUNNEL_NAME" "whoami.$DOMAIN"
cloudflared tunnel route dns "$TUNNEL_NAME" "uptime.$DOMAIN"

echo "✅ Cloudflare Tunnel setup complete!"
echo ""
echo "📝 Next steps:"
echo "1. Deploy cloudflared: kubectl apply -f infrastructure/base/cloudflared/"
echo "2. Verify tunnel status: cloudflared tunnel info $TUNNEL_NAME"
echo "3. Test external access: curl -H 'Host: whoami.$DOMAIN' https://$DOMAIN"