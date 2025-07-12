# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a homelab infrastructure repository that combines **NixOS system configuration** with **Kubernetes application deployment using Flux CD**. It manages a two-node k3s cluster (homelab-0, homelab-1) running self-hosted applications.

## Architecture

The repository has two main components:

### NixOS Configuration
- **`flake.nix`**: Main Nix flake defining system configurations
- **`hosts/k3s/`**: Host-specific configurations for the k3s cluster nodes
- **`modules/`**: Reusable NixOS modules (k3s, sops, user management)
- **`lib/defaults.nix`**: Common library functions

### Kubernetes/Flux Configuration (`flux/`)
- **`apps/`**: Application deployments with base configurations and environment overlays
- **`infrastructure/`**: Core infrastructure components (cert-manager, ingress-nginx, longhorn, metallb)
- **`clusters/`**: Flux configuration per environment (staging/production)
- **`secrets/`**: SOPS-encrypted secrets

## Key Technologies

- **NixOS**: Declarative operating system configuration
- **K3s**: Lightweight Kubernetes distribution
- **Flux v2**: GitOps operator for Kubernetes
- **SOPS**: Secret encryption with age keys
- **Helm**: Package manager for Kubernetes applications
- **Kustomize**: Configuration management via overlays

## Common Commands

### NixOS System Management

```bash
# Initial deployment to a new host
nix run nixpkgs#nixos-anywhere -- \
  --flake .#homelab-0 \
  --generate-hardware-config nixos-generate-config ./hosts/k3s/hardware-configuration-homelab-0.nix \
  --extra-files ~/.config/sops/age \
  nixos@192.168.50.192

# Remote system update
nixos-rebuild switch --flake .#homelab-1 \
  --target-host root@192.168.50.184

# Build system configuration locally
nix build .#nixosConfigurations.homelab-0.config.system.build.toplevel
```

### Flux/Kubernetes Operations

```bash
# Validate all manifests and overlays
./flux/scripts/validate.sh

# Check Flux prerequisites
flux check --pre

# Watch Helm releases across all namespaces
flux get helmreleases --all-namespaces

# Watch kustomizations
flux get kustomizations --watch

# Force reconciliation
flux reconcile kustomization flux-system --with-source

# Build and preview overlays
kustomize build ./flux/apps/staging
kustomize build ./flux/apps/production
```

### Secret Management

```bash
# Encrypt a secret with SOPS
sops --age=age1gff6wle45ktarxc89vfqnq6qawwjcxd5jed4jnuhhddpeqxz6d7q8wq8gn \
  --encrypt --encrypted-regex '^(data|stringData)$' --in-place secret-file.yaml

# Edit encrypted secrets
sops secret-file.yaml
```

## Infrastructure Components

The k3s cluster runs the following core infrastructure:
- **cert-manager**: TLS certificate management with Let's Encrypt
- **ingress-nginx**: HTTP/HTTPS ingress controller
- **longhorn**: Distributed storage system
- **metallb**: Load balancer for bare metal
- **external-dns**: Automated DNS record management
- **postgresql**: Database server
- **monitoring**: Prometheus, Grafana, Loki stack

## Self-Hosted Applications

The cluster hosts various applications including:
- **capacitor**: Home automation/IoT platform
- **cloudflared**: Cloudflare tunnel for external access
- **dify**: AI/LLM application platform
- **freshrss**: RSS feed reader
- **homepage**: Dashboard/landing page
- **manyfold**: 3D printing management
- **microrealestate**: Real estate management
- **mongodb**: Document database
- **redis**: Caching and message broker

## Development Workflow

1. **NixOS changes**: Modify host configurations in `hosts/` or modules in `modules/`, then deploy with `nixos-rebuild`
2. **Application changes**: Modify configurations in `flux/apps/`, changes are automatically synced by Flux
3. **Infrastructure changes**: Modify configurations in `flux/infrastructure/`, validate with `./flux/scripts/validate.sh`
4. **Secrets**: Encrypt with SOPS before committing

## Cluster Architecture

- **homelab-0** (192.168.50.104): k3s master node running on ThinkCentre i7
- **homelab-1** (192.168.50.184): k3s worker node running on ThinkCentre i5
- **Storage**: Longhorn distributed storage across both nodes
- **Networking**: metallb for load balancing, ingress-nginx for HTTP routing

The infrastructure follows GitOps principles with Flux monitoring the repository and automatically applying changes to maintain desired state.