# Agent Guidelines for Server Config

## Repository Overview

This is a homelab infrastructure repository that combines **NixOS system configuration using Colmena** with **Kubernetes application deployment using Flux CD**. It manages a two-node k3s cluster (homelab-0, homelab-1) running self-hosted applications.

## Architecture

The repository has two main components:

### NixOS Configuration

- **`flake.nix`**: Main Nix flake defining system configurations using Colmena for multi-node management
  - `homelab-0`: Master node (isMaster=true) at 192.168.50.104
  - `homelab-1`: Worker node (master points to 192.168.50.104) at 192.168.50.103
- **`lib/defaults.nix`**: Contains helper functions for Colmena configuration:
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

- NixOS Kubernetes Nodes/Hosts
  - **NixOS**: Declarative operating system configuration
  - **Colmena**: Multi-node NixOS deployment and management
  - **Disko**: Declarative disk partitioning (automated during nixos-anywhere deployment)
  - **K3s**: Lightweight Kubernetes distribution (servicelb and traefik disabled in favor of metallb/ingress-nginx)
  - **SOPS**: Secret encryption with age keys (requires age key at `~/.config/sops/age/keys.txt` on deployment machine)
- K3s Kubernetes Cluster
  - **Flux v2**: GitOps operator for Kubernetes
  - **Helm**: Package manager for Kubernetes applications
  - **Kustomize**: Configuration management via overlays

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
# Configuration in .sops.yaml defines primary and homelab age keys for different paths.
```

## Infrastructure Components

The k3s cluster runs the following core infrastructure:

- **cert-manager**: TLS certificate management with Let's Encrypt
- **ingress-nginx**: HTTP/HTTPS ingress controller
- **longhorn**: Distributed storage system
- **metallb**: Load balancer for bare metal
- **external-dns**: Automated DNS record management
- **postgresql**: Database server
- **monitoring**: kube-prometheus-stack (Prometheus + Grafana) and loki-stack (Loki + Promtail) for observability

## Self-Hosted Applications

The cluster hosts various applications managed via Flux:

- **actualbudget**: Personal finance budgeting tool
- **capacitor**: File upload and sharing service
- **cloudflared**: Cloudflare Tunnel client for secure access
- **dify**: AI application development platform
- **freshrss**: Self-hosted RSS aggregator
- **home-assistant**: Home automation platform
- **homepage**: Dashboard/landing page
- **manyfold**: Note-taking and knowledge management
- **mongodb**: NoSQL database
- **n8n**: Workflow automation platform
- **postgresql**: SQL database server
- **redis**: In-memory data store
- **supabase**: Backend-as-a-service platform with PostgreSQL

## Development Workflow

1. **NixOS changes**: Modify host configurations in `hosts/` or modules in `modules/`, then deploy with `nixos-rebuild switch --flake .#{hostname} --target-host root@{ip}` (or use `colmena apply` for multi-node deployment)
2. **Application changes**: Modify configurations in `flux/apps/`, changes are automatically synced by Flux (usually within 1-5 minutes)
3. **Infrastructure changes**: Modify configurations in `flux/infrastructure/`, validate with `./flux/scripts/validate.sh` before committing
4. **Secrets**: Always encrypt with SOPS before committing. Use `--encrypted-regex '^(data|stringData)$'` for Kubernetes secrets
5. **Testing overlays**: Use `kustomize build ./flux/apps/{environment}` to preview the final manifests before committing

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

The infrastructure follows GitOps principles with Flux monitoring the repository and automatically applying changes to maintain desired state.

## Important Architecture Details

- **mkNodeSpecialArgs helper**: The `lib/defaults.nix` file contains the `mkNodeSpecialArgs` function which creates custom host configuration parameters for Colmena.
- **Shared configuration**: Both nodes use the same `hosts/k3s/configuration.nix` but with different host-specific parameters passed via `custHostConfig`.
- **k3s module structure**: The k3s module includes `longhorn.nix` and `nfs.nix` submodules for additional storage options.
- **k3s customization**: The k3s module (`modules/k3s/default.nix`) disables default servicelb and traefik, enables metrics endpoints, and configures etcd metrics exposure.
- **Flux performance**: The production cluster has Flux controllers patched to run with `--concurrent=20` and `--requeue-dependency=5s` for faster reconciliation.
- **NixOS version**: Uses nixpkgs 25.11 with system.stateVersion "24.05" for compatibility.
- **Nix cache configuration**: Multiple substituters configured for faster builds (CUDA, Hyprland, devenv, nix-gaming, nix-community caches).

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
