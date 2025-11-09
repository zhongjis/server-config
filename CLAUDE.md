# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a homelab infrastructure repository that combines **NixOS system configuration** with **Kubernetes application deployment using Flux CD**. It manages a two-node k3s cluster (homelab-0, homelab-1) running self-hosted applications.

## Architecture

The repository has two main components:

### NixOS Configuration
- **`flake.nix`**: Main Nix flake defining system configurations using `mkK3sNode` helper
  - `homelab-0`: Master node (isMaster=true)
  - `homelab-1`: Worker node (masterAddr points to homelab-0)
- **`lib/defaults.nix`**: Contains `mkK3sNode` helper function that creates NixOS configurations with:
  - disko module for automated disk partitioning
  - sops-nix module for secret management
  - Custom host configuration parameters (hostName, isK3sMaster, masterAddr)
- **`hosts/k3s/`**: Shared k3s node configuration
  - `configuration.nix`: Base configuration imported by both nodes
  - `disko-config.nix`: Disk partitioning scheme
  - `hardware-configuration-{hostname}.nix`: Hardware-specific settings per node
- **`modules/`**: Reusable NixOS modules
  - `k3s/`: k3s service configuration with disabled servicelb/traefik, metrics enabled
  - `sops.nix`: SOPS age key management
  - `user.nix`: User account configuration

### Kubernetes/Flux Configuration (`flux/`)
- **`apps/`**: Application deployments with base configurations and environment overlays
  - `base/`: Helm and plain manifest definitions for each app
  - `staging/`: Staging environment overlay
  - `production/`: Production environment overlay
- **`infrastructure/`**: Core infrastructure components (cert-manager, ingress-nginx, longhorn, metallb)
- **`clusters/`**: Flux configuration per environment (staging/production)
  - Contains Flux GitOps toolkit components and sync configuration
  - Patches for increased concurrency (--concurrent=20) and reduced requeue time (5s)
- **`monitoring/`**: Observability stack (Prometheus, Grafana, Loki)
- **`secrets/`**: SOPS-encrypted secrets
- **`scripts/validate.sh`**: Validation script using kubeconform and kustomize

## Key Technologies

- **NixOS**: Declarative operating system configuration
- **Disko**: Declarative disk partitioning (automated during nixos-anywhere deployment)
- **K3s**: Lightweight Kubernetes distribution (servicelb and traefik disabled in favor of metallb/ingress-nginx)
- **Flux v2**: GitOps operator for Kubernetes
- **SOPS**: Secret encryption with age keys (requires age key at `~/.config/sops/age/keys.txt` on deployment machine)
- **Helm**: Package manager for Kubernetes applications
- **Kustomize**: Configuration management via overlays

## Common Commands

### NixOS System Management

```bash
# Initial deployment to a new host (requires SOPS age keys at ~/.config/sops/age)
# Linux:
nix run nixpkgs#nixos-anywhere -- \
  --flake .#homelab-0 \
  --generate-hardware-config nixos-generate-config ./hosts/k3s/hardware-configuration-homelab-0.nix \
  --extra-files /home/zshen/.config/sops/age \
  nixos@192.168.50.192

# macOS:
nix run nixpkgs#nixos-anywhere -- \
  --flake .#homelab-0 \
  --generate-hardware-config nixos-generate-config ./hosts/k3s/hardware-configuration-homelab-0.nix \
  --extra-files /Users/zshen/.config/sops/age \
  nixos@192.168.50.192

# Remote system update (after initial deployment)
nixos-rebuild switch --flake .#homelab-1 \
  --target-host root@192.168.50.184

# Build system configuration locally (useful for testing before deployment)
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
# Encrypt a Kubernetes secret with SOPS (use --encrypted-regex for K8s secrets)
sops --age=age1gff6wle45ktarxc89vfqnq6qawwjcxd5jed4jnuhhddpeqxz6d7q8wq8gn \
  --encrypt --encrypted-regex '^(data|stringData)$' --in-place secret-file.yaml

# Encrypt a NixOS secret with SOPS (stored in secrets/homelab.yaml)
sops --age=age1gff6wle45ktarxc89vfqnq6qawwjcxd5jed4jnuhhddpeqxz6d7q8wq8gn \
  --encrypt --in-place secrets/homelab.yaml

# Edit encrypted secrets (automatically decrypts/re-encrypts)
sops secret-file.yaml

# Note: Age keys must exist at ~/.config/sops/age/keys.txt on the machine running SOPS
# On deployed NixOS hosts, keys are copied to /var/lib/sops-nix/keys.txt during deployment
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

1. **NixOS changes**: Modify host configurations in `hosts/` or modules in `modules/`, then deploy with `nixos-rebuild switch --flake .#{hostname} --target-host root@{ip}`
2. **Application changes**: Modify configurations in `flux/apps/`, changes are automatically synced by Flux (usually within 1-5 minutes)
3. **Infrastructure changes**: Modify configurations in `flux/infrastructure/`, validate with `./flux/scripts/validate.sh` before committing
4. **Secrets**: Always encrypt with SOPS before committing. Use `--encrypted-regex '^(data|stringData)$'` for Kubernetes secrets
5. **Testing overlays**: Use `kustomize build ./flux/apps/{environment}` to preview the final manifests before committing

## Cluster Architecture

- **homelab-0** (192.168.50.104): k3s master node running on ThinkCentre i7
  - Configured with `isMaster=true` in flake.nix
  - Runs `k3s server --cluster-init`
- **homelab-1** (192.168.50.184): k3s worker node running on ThinkCentre i5
  - Configured with `masterAddr="192.168.50.104"` to join the cluster
  - Runs `k3s server` pointing to homelab-0
- **Storage**: Longhorn distributed storage across both nodes
- **Networking**:
  - metallb for load balancing (k3s servicelb disabled)
  - ingress-nginx for HTTP routing (k3s traefik disabled)
  - Firewall: TCP ports 2379-2381, 6443, 9100, 10249-10250, 10257, 10259, 5001; UDP ports 8472, 51820-51821

The infrastructure follows GitOps principles with Flux monitoring the repository and automatically applying changes to maintain desired state.

## Important Architecture Details

- **mkK3sNode helper**: The `lib/defaults.nix` file contains the `mkK3sNode` function which generates NixOS system configurations. It accepts parameters like `isMaster` and `masterAddr` to configure cluster topology.
- **Shared configuration**: Both nodes use the same `hosts/k3s/configuration.nix` but with different host-specific parameters passed via `custHostConfig`.
- **k3s customization**: The k3s module (`modules/k3s/default.nix`) disables default servicelb and traefik, enables metrics endpoints, and configures etcd metrics exposure.
- **Flux performance**: The production cluster has Flux controllers patched to run with `--concurrent=20` and `--requeue-dependency=5s` for faster reconciliation.