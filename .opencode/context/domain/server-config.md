# Server Configuration Domain

## Overview

This repository manages a **homelab infrastructure** with a two-part architecture:

1. **NixOS Host Configuration** - Declarative system configuration for physical/virtual machines
2. **FluxCD GitOps Configuration** - Kubernetes application deployment and management

## Architecture Components

### Part 1: NixOS Host Configuration (Base Directory)

**Purpose**: Configure and manage the Kubernetes nodes themselves.

**Key Technologies**:
- **NixOS**: Declarative Linux distribution with immutable infrastructure patterns
- **Colmena**: Multi-node deployment tool for NixOS configurations
- **Disko**: Declarative disk partitioning and filesystem management
- **K3s**: Lightweight Kubernetes distribution
- **SOPS-nix**: Secret management with age encryption

**Hosts**:
- **homelab-0** (192.168.50.104): k3s master node (ThinkCentre i7)
  - `isMaster=true` in flake.nix
  - Runs `k3s server --cluster-init`
- **homelab-1** (192.168.50.103): k3s worker node (ThinkCentre i5)
  - `master="192.168.50.104"` to join cluster
  - Runs `k3s server` pointing to homelab-0

**Key Files**:
- `flake.nix`: Main Nix flake defining system configurations
- `lib/defaults.nix`: Helper functions for Colmena configuration
- `hosts/k3s/`: Shared k3s node configuration
- `modules/`: Reusable NixOS modules (k3s, sops, user)

### Part 2: FluxCD GitOps Configuration (`flux/` Directory)

**Purpose**: Manage Kubernetes applications and infrastructure via GitOps.

**Key Technologies**:
- **Flux CD v2**: GitOps operator for Kubernetes
- **Helm**: Package manager for Kubernetes applications
- **Kustomize**: Configuration management via overlays
- **SOPS**: Secret encryption with age keys
- **CloudNativePG**: PostgreSQL operator for Kubernetes

**Infrastructure Stack**:
- **cert-manager**: TLS certificate management with Let's Encrypt
- **ingress-nginx**: HTTP/HTTPS ingress controller (replaces k3s traefik)
- **longhorn**: Distributed block storage
- **metallb**: Load balancer for bare metal (replaces k3s servicelb)
- **external-dns**: Automated DNS record management
- **monitoring**: kube-prometheus-stack + loki-stack

## Key Architectural Decisions

### 1. NixOS for Host Management
- **Why**: Declarative, reproducible system configuration
- **Benefits**: Atomic upgrades, rollback capability, consistent environments
- **Implementation**: Colmena for multi-node management, flakes for dependency pinning

### 2. K3s over Full Kubernetes
- **Why**: Lightweight, suitable for resource-constrained homelab
- **Customizations**: Disabled servicelb (using metallb), disabled traefik (using ingress-nginx)
- **Storage**: Longhorn for distributed storage across nodes

### 3. FluxCD for GitOps
- **Why**: Continuous reconciliation, Git as single source of truth
- **Patterns**: Kustomize overlays for environments, Helm for application packaging
- **Performance**: Patched for faster reconciliation (`--concurrent=20`, `--requeue-dependency=5s`)

### 4. Secret Management with SOPS
- **Why**: Encrypted secrets in Git, age encryption for simplicity
- **Pattern**: Different age keys for NixOS vs Kubernetes secrets
- **Location**: `secrets/` for NixOS, `flux/secrets/production/` for Kubernetes

## Application Patterns

### Standard Application Structure
```
flux/apps/base/<app-name>/
├── Namespace.yaml          # Creates application namespace
├── HelmRepo.yaml          # Helm repository source (or OCIRepository.yaml)
├── HelmRelease.yaml       # Main deployment with values
├── kustomization.yaml     # Resource list
├── Cluster.yaml           # Optional: CloudNativePG PostgreSQL cluster
└── GrafanaDashboard.yaml  # Optional: Monitoring dashboard
```

### Database Applications
Applications requiring PostgreSQL use CloudNativePG:
- `Cluster.yaml` defines PostgreSQL cluster
- `HelmRelease.yaml` uses `dependsOn` to wait for database
- Credentials from auto-generated secrets (`<app>-cnpg-cluster-app`)

### Secret Naming Patterns
- **New applications**: `<app>-secrets-flux.yaml`
- **Legacy patterns**: `<app>-secrets-fluxcd.yaml`, `<app>-secrets.yaml`
- **Location**: `flux/secrets/production/`

## Network Architecture

### Internal Networking
- **Service CIDR**: `10.43.0.0/16`
- **Pod CIDR**: `10.42.0.0/16`
- **Cluster DNS**: `10.43.0.10`

### External Access
- **Ingress**: ingress-nginx controller with TLS termination
- **Load Balancing**: metallb for LoadBalancer services
- **DNS**: external-dns for automatic DNS record management
- **Tunnels**: cloudflared for secure external access

### Firewall Rules
Open ports (TCP unless noted):
- `2379-2381`: etcd client/server communication
- `6443`: Kubernetes API server
- `9100`: node-exporter metrics
- `10249-10250`: kubelet metrics/communication
- `10257`: kube-controller-manager
- `10259`: kube-scheduler
- `5001`: longhorn manager
- `8472` (UDP): flannel VXLAN
- `51820-51821` (UDP): WireGuard (optional)

## Storage Architecture

### Primary Storage: Longhorn
- **Purpose**: Distributed block storage across both nodes
- **Configuration**: Replication factor 2 for high availability
- **Usage**: Default storage class for persistent volumes

### Backup Strategy
- **Longhorn backups**: To external NFS or S3 (if configured)
- **Database backups**: CloudNativePG native backups
- **Configuration backups**: Git repository with encrypted secrets

## Monitoring & Observability

### Stack Components
- **Prometheus**: Metrics collection and alerting
- **Grafana**: Dashboards and visualization
- **Loki**: Log aggregation
- **Promtail**: Log collection

### Application Integration
- **ServiceMonitors**: For Prometheus discovery
- **GrafanaDashboards**: ConfigMaps with JSON dashboards
- **Metrics endpoints**: Exposed by applications and infrastructure

## Development Workflow

### 1. NixOS Changes
```bash
# Modify host configurations or modules
colmena apply  # Deploy to all nodes
# or
nixos-rebuild switch --flake .#homelab-0 --target-host root@192.168.50.104
```

### 2. Application Changes
```bash
# Modify flux/apps/base/<app>/
./flux/scripts/validate.sh  # Validate before commit
git add . && git commit -m "feat: update <app>"
git push origin main  # Flux reconciles automatically
```

### 3. Secret Management
```bash
# Encrypt new secrets
sops --age=age1gff6wle45ktarxc89vfqnq6qawwjcxd5jed4jnuhhddpeqxz6d7q8wq8gn \
  --encrypt --encrypted-regex '^(data|stringData)$' --in-place secret.yaml
```

## Disaster Recovery

### Recovery Procedures
1. **Host failure**: Rebuild from NixOS configuration using nixos-anywhere
2. **Cluster failure**: Rebootrap k3s, restore from Longhorn backups
3. **Flux failure**: Reinstall Flux from git, reconcile existing manifests
4. **Data loss**: Restore from Longhorn/CloudNativePG backups

### Backup Locations
- **Configuration**: Git repository (primary)
- **Secrets**: Git repository (encrypted with SOPS)
- **Data**: Longhorn volumes with replication
- **Databases**: CloudNativePG native backups

## Technology Versions

### Current Versions
- **NixOS**: 25.11 (via nixpkgs channel)
- **K3s**: Latest stable (managed by NixOS module)
- **Flux CD**: v2.7.5
- **Helm**: Latest (via flux components)

### Version Pinning Strategy
- **Nixpkgs**: Pinned via flake.lock
- **Helm charts**: Exact versions in HelmRelease.yaml (no semver ranges)
- **Container images**: Specific tags in values

## Constraints & Limitations

### Hardware Constraints
- **Nodes**: 2 x ThinkCentre mini PCs (i7 + i5)
- **Memory**: 32GB + 16GB = 48GB total
- **Storage**: NVMe SSDs in each node
- **Network**: Gigabit Ethernet, residential internet

### Software Constraints
- **Single cluster**: Production only (staging is minimal)
- **Bare metal**: No cloud provider integrations
- **Self-hosted**: All services run on-premise
- **GitOps**: All changes via Git, no manual kubectl apply

## Future Considerations

### Planned Improvements
1. **Staging cluster**: More comprehensive testing environment
2. **Backup automation**: Scheduled backups to external storage
3. **Monitoring alerts**: Alertmanager configuration for critical issues
4. **Security hardening**: Network policies, pod security standards

### Scalability Considerations
- **Vertical scaling**: Upgrade node hardware
- **Horizontal scaling**: Add more worker nodes
- **Application scaling**: HPA configurations for workload-based scaling

## Reference Documentation

- **Base AGENTS.md**: `/home/zshen/personal/server-config/AGENTS.md` (NixOS/host configuration)
- **Flux AGENTS.md**: `/home/zshen/personal/server-config/flux/AGENTS.md` (FluxCD/Kubernetes GitOps)
- **OpenCode Index**: `.opencode/context/index.md`
- **Agent Rules**: `.opencode/context/core/standards/rules.md`
- **Workflows**: `.opencode/context/core/workflows/`