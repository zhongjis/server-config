# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a GitOps repository for managing Kubernetes homelab infrastructure using Flux v2, Kustomize, and Helm. It follows the flux2-kustomize-helm-example pattern with separate staging and production environments.

## Architecture

The repository structure follows GitOps principles:

- **apps/**: Application deployments with base configurations and environment overlays
  - `base/`: Common Helm release definitions (Rancher, Capacitor)
  - `staging/`: Staging-specific configurations 
  - `production/`: Production-specific configurations
- **infrastructure/**: Core infrastructure components
  - `controllers/`: Infrastructure services (cert-manager, ingress-nginx, longhorn, metallb)
  - `configs/`: Configuration resources (cluster issuers, network policies)
- **clusters/**: Flux configuration per environment
  - `staging/`: Staging cluster Flux setup
  - `production/`: Production cluster Flux setup

## Key Technologies

- **Flux v2**: GitOps operator for Kubernetes
- **Kustomize**: Configuration management via overlays
- **Helm**: Package manager for applications
- **Infrastructure**: cert-manager, ingress-nginx, longhorn storage, metallb load balancer

## Common Commands

### Validation
```bash
# Validate all manifests and kustomizations
./scripts/validate.sh
```

### Flux Operations
```bash
# Check Flux prerequisites
flux check --pre

# Watch Helm releases across all namespaces
flux get helmreleases --all-namespaces

# Watch kustomizations
flux get kustomizations --watch

# Force reconciliation
flux reconcile kustomization flux-system --with-source
```

### Kustomize Operations
```bash
# Build and preview staging overlay
kustomize build ./apps/staging

# Build and preview production overlay  
kustomize build ./apps/production

# Build infrastructure controllers
kustomize build ./infrastructure/controllers
```

## Environment Management

The repository supports multiple environments through Kustomize overlays:

- **Staging**: Uses development/alpha versions, includes test configurations
- **Production**: Uses stable versions only, production-grade settings

Dependencies are managed through Flux Kustomization `dependsOn` fields:
1. Infrastructure controllers are deployed first
2. Infrastructure configs are applied after controllers
3. Applications are deployed after infrastructure is ready

## Infrastructure Components

Core infrastructure managed by this repository:
- **cert-manager**: TLS certificate management
- **ingress-nginx**: Ingress controller
- **longhorn**: Distributed storage
- **metallb**: Load balancer for bare metal
- **rancher**: Kubernetes management platform

Environment-specific patches are applied via Kustomize to handle differences between staging and production (e.g., Let's Encrypt staging vs production servers).