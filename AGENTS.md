# Agent Guidelines for Server Config

## Repository Overview

This repository has a **two-part architecture**:

1. **NixOS Host Configuration** (this directory) - Declarative system configuration for Kubernetes nodes using Colmena
2. **FluxCD GitOps Configuration** (`flux/` subdirectory) - Kubernetes application deployment and management via GitOps

**Important**: When asked about Kubernetes operations, always check `flux/AGENTS.md` first.

## Architecture

### Part 1: NixOS Configuration (This Directory)

#### Core Components
- **`flake.nix`**: Main Nix flake defining system configurations using Colmena for multi-node management
  - `homelab-0`: Master node (isMaster=true) at 192.168.50.104
  - `homelab-1`: Worker node (master points to 192.168.50.104) at 192.168.50.103
- **`lib/defaults.nix`**: Helper functions for Colmena configuration:
  - `mkNodeSpecialArgs`: Creates custom host configuration parameters (hostName, isK3sMaster, masterAddr)
  - `mkHive`: Creates Colmena node configurations with sops-nix and disko modules
- **`hosts/k3s/`**: Shared k3s node configuration
  - `configuration.nix`: Base configuration imported by both nodes with firewall rules, timezone, system packages
  - `disko-config.nix`: Disk partitioning scheme for NVMe drives
  - `hardware-configuration-{hostname}.nix`: Hardware-specific settings per node (optional)
- **`modules/`**: Reusable NixOS modules
  - `default.nix`: Global nix configuration with cache settings and experimental features
  - `k3s/`: k3s service configuration with disabled servicelb/traefik, metrics enabled, etcd metrics
  - `sops.nix`: SOPS age key management with sops package
  - `user.nix`: User account configuration with SSH keys and hashed passwords

### Part 2: Kubernetes/Flux Configuration (`flux/` Directory)

**For all FluxCD and Kubernetes operations, refer to `flux/AGENTS.md`.**

Key components in `flux/`:
- **`apps/`**: Application deployments with base configurations and environment overlays
- **`infrastructure/`**: Core infrastructure components (cert-manager, ingress-nginx, longhorn, metallb)
- **`clusters/`**: Flux configuration per environment (staging/production)
- **`monitoring/`**: Observability stack (Prometheus, Grafana, Loki)
- **`secrets/`**: SOPS-encrypted secrets
- **`scripts/validate.sh`**: Validation script using kubeconform and kustomize

## Key Technologies

### NixOS Kubernetes Nodes/Hosts
- **NixOS**: Declarative operating system configuration
- **Colmena**: Multi-node NixOS deployment and management
- **Disko**: Declarative disk partitioning (automated during nixos-anywhere deployment)
- **K3s**: Lightweight Kubernetes distribution (servicelb and traefik disabled in favor of metallb/ingress-nginx)
- **SOPS**: Secret encryption with age keys (requires age key at `~/.config/sops/age/keys.txt` on deployment machine)

### K3s Kubernetes Cluster
- **Flux v2**: GitOps operator for Kubernetes - See `flux/AGENTS.md`
- **Helm**: Package manager for Kubernetes applications - See `flux/AGENTS.md`
- **Kustomize**: Configuration management via overlays - See `flux/AGENTS.md`

## Common Commands

### Colmena Deployment / NixOS Deployment
```bash
# Deploy configuration to all nodes using Colmena
colmena apply

# Apply to a specific node
colmena apply --on homelab-0

# Build configuration locally
colmena build
```

### Flux/Kubernetes Operations
**All Flux commands are documented in `flux/AGENTS.md`. Key references:**

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

#### NixOS Secrets (this directory)
```bash
# Encrypt a NixOS secret with SOPS (stored in secrets/homelab.yaml)
sops --age=age1gff6wle45ktarxc89vfqnq6qawwjcxd5jed4jnuhhddpeqxz6d7q8wq8gn \
  --encrypt --in-place secrets/homelab.yaml

# Edit encrypted secrets (automatically decrypts/re-encrypts)
sops secrets/homelab.yaml
```

#### Kubernetes Secrets (flux/ directory)
**Refer to `flux/AGENTS.md` for Kubernetes secret management.**

```bash
# Note: Age keys must exist at ~/.config/sops/age/keys.txt on the machine running SOPS
# On deployed NixOS hosts, keys are copied to /var/lib/sops-nix/keys.txt during deployment
# Configuration in .sops.yaml defines primary and homelab age keys for different paths.
```

## Infrastructure Components

The k3s cluster runs core infrastructure managed by FluxCD. For details, see `flux/AGENTS.md`.

## Application Patterns (FluxCD)

**For application deployment patterns, refer to `flux/AGENTS.md`.**

### Key Patterns:
- Application directory: `flux/apps/base/<app-name>/`
- Standard files: `Namespace.yaml`, `HelmRepo.yaml` or `OCIRepository.yaml`, `HelmRelease.yaml`, `kustomization.yaml`
- Optional files: `Cluster.yaml` (CloudNativePG), `GrafanaDashboard.yaml`
- Secret naming: `flux/secrets/production/<app>-secrets-flux.yaml` (new pattern)
- Legacy secret patterns: `*-secrets-fluxcd.yaml`, `*-secrets.yaml`

### Discovering Current Applications:
```bash
# List all deployed applications
ls /home/zshen/personal/server-config/flux/apps/base/
```

## Development Workflow

1. **NixOS changes**: Modify host configurations in `hosts/` or modules in `modules/`, then deploy with `colmena apply`
2. **Application changes**: Modify configurations in `flux/apps/`, changes are automatically synced by Flux
3. **Infrastructure changes**: Modify configurations in `flux/infrastructure/`, validate with `./flux/scripts/validate.sh` before committing
4. **Secrets**: Always encrypt with SOPS before committing
5. **Testing overlays**: Use `kustomize build ./flux/apps/{environment}` to preview manifests

## Cluster Architecture

- **homelab-0** (192.168.50.104): k3s master node running on ThinkCentre i7
  - Configured with `isMaster=true` in flake.nix
  - Runs `k3s server --cluster-init`
- **homelab-1** (192.168.50.103): k3s worker node running on ThinkCentre i5
  - Configured with `master="192.168.50.104"` to join the cluster
  - Runs `k3s server` pointing to homelab-0
- **Storage**: Longhorn distributed storage across both nodes
- **Networking**:
  - metallb for load balancing (k3s servicelb disabled)
  - ingress-nginx for HTTP routing (k3s traefik disabled)
  - Firewall: TCP ports 2379-2381, 6443, 9100, 10249-10250, 10257, 10259, 5001; UDP ports 8472, 51820-51821

## Important Architecture Details

- **mkNodeSpecialArgs helper**: The `lib/defaults.nix` file contains the `mkNodeSpecialArgs` function which creates custom host configuration parameters for Colmena.
- **Shared configuration**: Both nodes use the same `hosts/k3s/configuration.nix` but with different host-specific parameters passed via `custHostConfig`.
- **k3s module structure**: The k3s module includes `longhorn.nix` and `nfs.nix` submodules for additional storage options.
- **k3s customization**: The k3s module (`modules/k3s/default.nix`) disables default servicelb and traefik, enables metrics endpoints, and configures etcd metrics exposure.
- **NixOS version**: Uses nixpkgs 25.11 with system.stateVersion "24.05" for compatibility.
- **Nix cache configuration**: Multiple substituters configured for faster builds (CUDA, Hyprland, devenv, nix-gaming, nix-community caches).

**Note**: Flux performance tuning details are in `flux/AGENTS.md`.

## Agent Guidance

### OpenCode Standards
This repository uses OpenCode standards for consistent agent interactions. Key files:

- **Agent Rules**: `.opencode/context/core/standards/rules.md`
  - When to check which AGENTS.md file
  - Kubernetes context usage guidelines
  - Secret naming patterns
  - App discovery patterns

- **Code Standards**: `.opencode/context/core/standards/code.md`
  - YAML formatting (2-space indentation)
  - Kubernetes resource naming conventions
  - File naming patterns

- **Workflows**: `.opencode/context/core/workflows/`
  - `deploy-new-app.md`: Steps to deploy a new application
  - `update-flux.md`: Steps to update Flux components
  - `troubleshoot-flux.md`: Common Flux troubleshooting

- **Domain Context**: `.opencode/context/domain/server-config.md`
  - Two-part architecture overview
  - Technology stack details

### Core Agent Rules
1. **When asked about Kubernetes operations, always check `flux/AGENTS.md` first.**
2. **When working with Kubernetes operations, unless otherwise specified, use the default Kubernetes context.**
3. **For app-specific questions, first check the app's directory structure in `flux/apps/base/`.**
4. **New secrets should follow the pattern: `<app>-secrets-flux.yaml`.**
5. **Always run validation before committing changes: `./flux/scripts/validate.sh`.**

## Build/Test Commands

- **Validate all manifests**: `./flux/scripts/validate.sh`
- **Run CI tests**: Triggered via `.github/workflows/test.yaml`
- **Run e2e tests**: Triggered via `.github/workflows/e2e.yaml`
- **Manual validation**: `kubeconform -strict -ignore-missing-schemas <file.yaml>`

## Code Style Guidelines

- **YAML format**: 2-space indentation, lowercase for resource names
- **Kubernetes conventions**: Use `app.kubernetes.io/name` labels consistently
- **Flux GitOps**: Structure resources under `flux/apps/base/` and `flux/apps/production/`
- **File naming**: Use PascalCase for Kubernetes resources (e.g., `Deployment.yaml`, `Service.yaml`)
- **Kustomize**: All overlays must have `kustomization.yaml` with proper resource references
- **Secrets**: Use SOPS encryption, skip Secret validation in kubeconform
- **Image tags**: Pin specific versions (e.g., `v1.8.0`) with `imagePullPolicy: Always`
- **Namespace**: Every app should have its own namespace with matching resources

## Reference Documentation

- **Flux AGENTS.md**: `/home/zshen/personal/server-config/flux/AGENTS.md` - Complete FluxCD/Kubernetes documentation
- **OpenCode Index**: `.opencode/context/index.md` - All OpenCode standards and workflows
- **Agent Rules**: `.opencode/context/core/standards/rules.md` - Detailed agent interaction rules
- **Deploy New App**: `.opencode/context/core/workflows/deploy-new-app.md` - Step-by-step application deployment