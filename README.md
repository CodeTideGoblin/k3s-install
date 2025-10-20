# k3s-install

A production-ready k3s deployment repository demonstrating secure application hosting with external access via Cloudflare Tunnel. This repository follows Kubernetes best practices with Kustomize-based configuration management.

## 🏗️ Repository Structure

```
k3s-install/
├── apps/                          # Application configurations
│   ├── base/                     # Base configurations for all apps
│   │   ├── whoami/              # Demo web application
│   │   └── uptime/              # Uptime monitoring application
│   └── overlays/                 # Environment-specific configurations
├── infrastructure/               # Infrastructure components
│   ├── base/                     # Base infrastructure
│   │   ├── namespaces.yaml      # Namespace definitions
│   │   └── cloudflared/         # Cloudflare tunnel configuration
│   └── overlays/                 # Infrastructure overlays
│       └── metallb/             # MetalLB load balancer (optional)
├── overlays/                     # Environment deployments
│   ├── development/             # Development environment
│   ├── staging/                 # Staging environment
│   └── production/              # Production environment
├── scripts/                      # Operational scripts
│   ├── deploy.sh                # Deployment script
│   ├── validate.sh              # Validation script
│   ├── setup-cloudflared.sh     # Cloudflare tunnel setup
│   └── cleanup.sh               # Cleanup script
└── docs/                        # Documentation
```

## 🚀 Quick Start

### Prerequisites

- k3s cluster installed and running
- kubectl configured to access your cluster
- Cloudflare account (for external access)
- Domain name configured in Cloudflare

### 1. Initial Setup

```bash
# Disable swap (required for k3s)
sudo swapoff -a
sudo sed -i '/ swap / s/^/#/' /etc/fstab

# Configure Traefik for source IP preservation
kubectl edit svc traefik -n kube-system
# Set externalTrafficPolicy: Local
```

### 2. Deploy Infrastructure

```bash
# Deploy namespaces and cloudflared
kubectl apply -k infrastructure/
```

### 3. Setup Cloudflare Tunnel

```bash
# Run the setup script
./scripts/setup-cloudflared.sh my-tunnel yourdomain.com

# Or manually configure:
# 1. Install cloudflared on your system
# 2. Create tunnel: cloudflared tunnel create my-tunnel
# 3. Create secret with tunnel credentials
# 4. Configure DNS routes
```

### 4. Deploy Applications

```bash
# Deploy to production (default)
./scripts/deploy.sh

# Deploy to specific environment
./scripts/deploy.sh development
./scripts/deploy.sh staging
./scripts/deploy.sh production
```

### 5. Validate Deployment

```bash
# Run validation checks
./scripts/validate.sh

# Test endpoints
curl -H "Host: whoami.yourdomain.com" http://<traefik-ip>
curl -H "Host: uptime.yourdomain.com" http://<traefik-ip>
```

## 🎯 Deployment Environments

### Development
- Single replicas for cost efficiency
- Debug logging enabled
- Separate namespace (`apps-dev`)

### Staging
- Multiple replicas for testing
- Standard logging
- Separate namespace (`apps-staging`)

### Production
- High availability with multiple replicas
- Resource limits and PodDisruptionBudgets
- Production namespace (`apps`)

## 🔧 Configuration

### Domain Configuration

Update the domain in these files:
- `infrastructure/base/cloudflared/configmap.yaml`
- `apps/base/whoami/ingress.yaml`
- `apps/base/uptime/ingress.yaml`

### Resource Limits

Base resource allocations:
- **whoami**: 10m CPU/32Mi memory (requests), 50m CPU/64Mi memory (limits)
- **uptime**: 50m CPU/256Mi memory (requests), 500m CPU/1Gi memory (limits)
- **cloudflared**: 50m CPU/64Mi memory (requests), 250m CPU/256Mi memory (limits)

Production environments have higher resource limits configured.

### MetalLB (Optional)

For bare-metal load balancing:

```bash
# Deploy MetalLB
kubectl apply -k infrastructure/overlays/metallb/

# Update IP range in metallb-addr-pool.yaml if needed
```

## 🔒 Security Features

- All containers run as non-root users
- Privilege escalation disabled
- Read-only root filesystems where possible
- All capabilities dropped
- Resource requests and limits defined
- Network policies can be added for additional isolation

## 📊 Monitoring

Applications include:
- **Liveness probes**: Check application health
- **Readiness probes**: Ensure traffic only goes to ready pods
- **Resource monitoring**: CPU and memory usage tracking

## 🧪 Testing

```bash
# Test whoami endpoint
kubectl run test --image=curlimages/curl --rm -it -- \
  curl -H "Host: whoami.yourdomain.com" http://traefik.kube-system.svc.cluster.local

# Test uptime endpoint
kubectl run test --image=curlimages/curl --rm -it -- \
  curl -H "Host: uptime.yourdomain.com" http://traefik.kube-system.svc.cluster.local
```

## 🧹 Cleanup

```bash
# Cleanup specific environment
./scripts/cleanup.sh development

# Cleanup all environments (with confirmation)
./scripts/cleanup.sh all

# Force cleanup without confirmation
./scripts/cleanup.sh production --force
```

## 📝 Notes

- Uptime Kuma uses a 5Gi persistent volume claim for data storage
- Cloudflare Tunnel credentials are stored as Kubernetes secrets
- Traefik is used as the ingress controller (built into k3s)
- All applications route through Cloudflare Tunnel for secure external access

## 🤝 Contributing

1. Make changes to base configurations in `apps/base/` or `infrastructure/base/`
2. Test changes in development environment first
3. Update environment overlays as needed
4. Run validation scripts before committing

## 📚 Additional Resources

- [k3s Documentation](https://docs.k3s.io/)
- [Kustomize Documentation](https://kubectl.docs.kubernetes.io/guides/introduction/kustomize/)
- [Cloudflare Tunnel Documentation](https://developers.cloudflare.com/cloudflare-one/connections/connect-apps/)
- [MetalLB Documentation](https://metallb.universe.tf/)