# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Structure

This repository follows Kubernetes best practices with Kustomize-based configuration management:

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
└── scripts/                      # Operational scripts
    ├── deploy.sh                # Deployment script
    ├── validate.sh              # Validation script
    ├── setup-cloudflared.sh     # Cloudflare tunnel setup
    └── cleanup.sh               # Cleanup script
```

## Essential Commands

### Deployment Operations
```bash
# Deploy entire stack to production
kubectl apply -k .

# Deploy to specific environment
./scripts/deploy.sh development
./scripts/deploy.sh staging
./scripts/deploy.sh production

# Deploy specific components
./scripts/deploy.sh production infrastructure
./scripts/deploy.sh production apps
./scripts/deploy.sh production metallb
```

### Validation and Testing
```bash
# Validate deployment
./scripts/validate.sh

# Check deployment status
kubectl get all -A -l environment=production

# Test application endpoints
kubectl run test --image=curlimages/curl --rm -it -- \
  curl -H "Host: whoami.sotools.cc" http://traefik.kube-system.svc.cluster.local
```

### Cloudflare Tunnel Setup
```bash
# Automated setup
./scripts/setup-cloudflared.sh my-tunnel yourdomain.com

# Manual tunnel configuration
kubectl -n cloudflared create secret generic tunnel-credentials \
  --from-file=credentials.json=$HOME/.cloudflared/<TUNNEL_ID>.json
```

## Architecture Patterns

### Base Configuration Pattern
- All applications have base configurations in `apps/base/<app-name>/`
- Base configs include: deployment.yaml, service.yaml, ingress.yaml, kustomization.yaml
- Infrastructure components in `infrastructure/base/`

### Environment Overlay Pattern
- Environment-specific configs in `overlays/<environment>/`
- Each overlay can modify replicas, resources, namespaces, etc.
- Production includes PodDisruptionBudgets and higher resource limits

### Kustomize Structure
```yaml
# Base kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  - deployment.yaml
  - service.yaml
  - ingress.yaml
commonLabels:
  app.kubernetes.io/name: app-name
  app.kubernetes.io/component: component-type
namespace: apps
```

## Security Standards

All deployments follow these security patterns:
- Non-root containers (UID 65532 or 1000)
- `allowPrivilegeEscalation: false`
- `readOnlyRootFilesystem: true` where possible
- `capabilities.drop: ["ALL"]`
- Resource requests and limits defined
- Network policies can be added for additional isolation

## Key Configuration Files

### Application Configurations
- `apps/base/whoami/` - Demo application with minimal resources
- `apps/base/uptime/` - Monitoring app with persistent storage
- `apps/base/*/kustomization.yaml` - Kustomize configuration

### Infrastructure Components
- `infrastructure/base/namespaces.yaml` - Namespace definitions
- `infrastructure/base/cloudflared/` - Tunnel configuration
- `infrastructure/overlays/metallb/` - Optional load balancer

### Environment Overlays
- `overlays/development/` - Single replicas, debug logging
- `overlays/staging/` - Multiple replicas, standard logging
- `overlays/production/` - HA configuration, PDBs, resource limits

## Development Workflow

1. **Modify Base Configs**: Edit files in `apps/base/` or `infrastructure/base/`
2. **Test in Development**: Deploy to dev environment first
3. **Update Overlays**: Modify environment-specific patches if needed
4. **Validate Changes**: Run `./scripts/validate.sh`
5. **Deploy Progressively**: dev → staging → production

## Domain and DNS Configuration

Update these files for your domain:
- `infrastructure/base/cloudflared/configmap.yaml` - Tunnel hostname
- `apps/base/whoami/ingress.yaml` - Ingress host
- `apps/base/uptime/ingress.yaml` - Ingress host

Default domain: `sotools.cc` (update to your domain)

## Resource Management

Base resource allocations:
- **whoami**: 10m CPU/32Mi (requests), 50m CPU/64Mi (limits)
- **uptime**: 50m CPU/256Mi (requests), 500m CPU/1Gi (limits)
- **cloudflared**: 50m CPU/64Mi (requests), 250m CPU/256Mi (limits)

Production overlays include higher resource limits and PodDisruptionBudgets.

## Troubleshooting Commands

```bash
# Check pod status and events
kubectl describe pod <pod-name> -n <namespace>

# Check service endpoints
kubectl get endpoints -n apps

# Check ingress configuration
kubectl describe ingress <ingress-name> -n apps

# Check tunnel logs
kubectl logs -n cloudflared deployment/cloudflared

# Check resource usage
kubectl top pods -A
kubectl describe resourcequota -A
```

## Cleanup Operations

```bash
# Cleanup specific environment
./scripts/cleanup.sh development

# Cleanup with confirmation bypass
./scripts/cleanup.sh production --force

# Cleanup everything
./scripts/cleanup.sh all
```