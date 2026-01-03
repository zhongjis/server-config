# Agent Guidelines for Flux CD Configuration

## Context

**This is the `flux/` subdirectory** of a larger repository that manages a homelab infrastructure with two-part architecture:
1. **NixOS Host Configuration** (base directory) - Managed via base `AGENTS.md`
2. **FluxCD GitOps Configuration** (this directory) - Kubernetes application deployment via GitOps

## Directory Overview

This is a FluxCD-based GitOps repository managing a Kubernetes cluster with multiple self-hosted applications. The repository follows the Flux v2 structure with Kustomize overlays for different environments (production/staging). Flux continuously reconciles the cluster state with this Git repository.

The repository follows a **six-component structure**:

1. **clusters/** - Flux configuration entry points
   - `clusters/production/` - Production cluster Flux Kustomizations with performance patches
   - `clusters/staging/` - Staging cluster Flux Kustomizations
   - Each contains `infrastructure.yaml` and `apps.yaml` that define reconciliation order

2. **infrastructure/** - Platform-level components
   - `infrastructure/controllers/` - Helm releases for cluster controllers (cert-manager, ingress-nginx, metallb, longhorn, cnpg-operator, external-dns)
   - `infrastructure/configs/` - Custom resources that depend on controllers (ClusterIssuers, MetalLB pools, CoreDNS configs)

3. **apps/** - Application deployments
   - `apps/base/` - Base Helm releases and manifests for each application
   - `apps/production/` - Production Kustomize overlay (references apps to deploy)
   - `apps/staging/` - Staging Kustomize overlay

4. **monitoring/** - Observability stack (Prometheus, Grafana, Loki)
   - `monitoring/controllers/` - kube-prometheus-stack and loki-stack
   - `monitoring/configs/` - Grafana dashboards

5. **secrets/** - SOPS-encrypted secrets
   - `secrets/production/` - Encrypted Kubernetes Secrets for production

6. **scripts/** - Validation and utility scripts
   - `scripts/validate.sh` - Pre-commit validation using kubeconform

## Key Architecture Patterns

### Reconciliation Order via dependsOn

Flux enforces deployment order using `dependsOn`:

- Infrastructure controllers → Infrastructure configs → Apps
- Example: cert-manager must be ready before ClusterIssuers can be created
- Apps can depend on other apps (e.g., freshrss depends on freshrss-cnpg-cluster)

### Application Structure Pattern

Each application in `apps/base/<app>/` follows this structure:

- `Namespace.yaml` - Creates the application namespace
- `HelmRepo.yaml` or `OCIRepository.yaml` - Defines the Helm chart source
- `HelmRelease.yaml` - Main deployment with values configuration
- `kustomization.yaml` - Lists all resources
- Optional: `GrafanaDashboard.yaml`, CloudNativePG `Cluster.yaml`

### Secret Management

Secrets are managed using SOPS with age encryption:

- Encrypted secrets live in `secrets/production/`
- HelmReleases reference secrets via `valuesFrom` to inject values into Helm charts
- **New secret pattern**: `<app>-secrets-flux.yaml` (preferred for new applications)
- **Legacy patterns**: `<app>-secrets-fluxcd.yaml`, `<app>-secrets.yaml` (existing files)
- Encryption command: `sops --age=age1gff6wle45ktarxc89vfqnq6qawwjcxd5jed4jnuhhddpeqxz6d7q8wq8gn --encrypt --encrypted-regex '^(data|stringData)$' --in-place <file>.yaml`

### Environment-Specific Configuration

Production uses JSON patches in `clusters/production/infrastructure.yaml`:

- Example: Replaces Let's Encrypt staging server with production server for ClusterIssuer
- Patches applied at the Flux Kustomization level, not in app manifests

### Performance Optimizations

Flux controllers are configured for faster reconciliation:

- `--concurrent=20` for parallel processing
- `--requeue-dependency=5s` for faster dependency resolution
- Configured via patches in `clusters/production/infrastructure.yaml`

### Ingress and TLS

All applications with ingress use:

- `className: nginx` for ingress-nginx controller
- `kubernetes.io/tls-acme: "true"` annotation
- Certificates auto-issued via cert-manager using cloudflare-issuer (DNS-01 challenge)
- Homepage integration via `gethomepage.dev/*` annotations

## Common Commands

### Flux Operations

Check Flux status:

```bash
flux get kustomizations
flux get helmreleases --all-namespaces
```

Force reconciliation:

```bash
flux reconcile kustomization flux-system --with-source
flux reconcile helmrelease <name> -n <namespace>
```

Check for validation errors:

```bash
flux logs --level=error
```

### Validation

Validate manifests before committing:

```bash
./scripts/validate.sh
```

This script validates:

- YAML syntax using yq
- Flux Kustomizations and HelmReleases using kubeconform
- All kustomize overlays

### Upgrading Flux

Export current Flux components:

```bash
flux install --export > ./clusters/production/flux-system/gotk-components.yaml
```

### Working with Secrets

Decrypt a secret for viewing:

```bash
sops -d secrets/production/<app>-secrets.yaml
```

Encrypt a new secret:

```bash
sops --age=age1gff6wle45ktarxc89vfqnq6qawwjcxd5jed4jnuhhddpeqxz6d7q8wq8gn \
  --encrypt --encrypted-regex '^(data|stringData)$' --in-place <file>.yaml
```

## Application Deployment Patterns

### Standard Helm-based Application

Most apps use external Helm charts with custom values. Key components:

1. Define HelmRepository source (or OCIRepository for OCI-based charts)
2. Create HelmRelease with chart version pinned
3. Use `valuesFrom` to inject secrets from Kubernetes Secrets
4. Configure ingress, persistence (usually Longhorn), and resource limits

### Applications with CloudNativePG

Apps requiring PostgreSQL (freshrss, n8n, authentik, dify, mlflow) use CloudNativePG operator:

- Define a `Cluster.yaml` in the app directory
- HelmRelease uses `dependsOn` to wait for the cluster
- Database credentials injected from auto-generated secrets (`<app>-cnpg-cluster-app`)

### Applications with External Dependencies

Apps like n8n depend on shared services:

- PostgreSQL: `postgresql.postgresql.svc.cluster.local`
- Redis: `redis-master.redis.svc.cluster.local`
- Credentials injected via `valuesFrom` from secrets

### Queue-based Scaling Pattern (n8n example)

n8n uses separate main/worker/webhook pods with HPA:

- Main pod: API and UI
- Worker pods: Job execution with autoscaling (3-15 replicas)
- Webhook pods: Webhook handling with autoscaling
- Redis for queue coordination

### Multi-component Applications (minio example)

Some apps have multiple components:
- `minio/operator/`: MinIO operator deployment
- `minio/tenant/`: MinIO tenant deployment
- Each with separate namespace and HelmRelease

## Important Notes

### Version Pinning

All HelmReleases specify exact chart versions (e.g., `version: 1.19.2`), not semver ranges. This ensures predictable deployments and requires manual version updates.

### Namespace Convention

Each application deploys to its own namespace, typically matching the app name. Namespace is created by the app itself in `Namespace.yaml`.

### Storage Classes

Primary storage class: `longhorn` (distributed block storage)

- Used for persistent volumes in HelmReleases
- Configured in controller HelmRelease values

### Monitoring Integration

Apps with Prometheus metrics expose ServiceMonitors:

- Namespace: usually `monitoring`
- Labels: `release: prometheus` for discovery
- Example in n8n HelmRelease configuration

### Homepage Dashboard

Applications visible on homepage dashboard use annotations:

- `gethomepage.dev/enabled: "true"`
- `gethomepage.dev/name: <App Name>`
- `gethomepage.dev/group: <Category>`
- `gethomepage.dev/description: <Description>`

### Path Prefixes

All file paths in Flux Kustomizations use `./flux/` prefix because the repository is a subdirectory of a parent repo:

- `path: ./flux/apps/production`
- `path: ./flux/infrastructure/controllers`

## Infrastructure Controllers

The cluster uses these core controllers (defined in `infrastructure/controllers/`):

- **cert-manager** (v1.19.2) - Certificate management with Cloudflare DNS-01 solver
- **ingress-nginx** - Ingress controller for HTTP(S) traffic
- **metallb** - Bare-metal load balancer for LoadBalancer services
- **longhorn** - Distributed block storage
- **cnpg-operator** - CloudNativePG for PostgreSQL clusters
- **external-dns** - Automatic DNS record management

## Adding a New Application

1. Create directory structure: `apps/base/<app>/`
2. Add manifests: Namespace, HelmRepo/OCIRepository, HelmRelease, kustomization
3. If secrets needed, create encrypted secret in `secrets/production/` following naming pattern
4. Reference secret in HelmRelease via `valuesFrom`
5. Add app to `apps/production/kustomization.yaml` resources list
6. Run `./scripts/validate.sh` to validate
7. Commit and push - Flux will reconcile automatically

For detailed steps, see `.opencode/context/core/workflows/deploy-new-app.md`.

## Troubleshooting

### Common Issues

1. **Kustomization not reconciling**:
   ```bash
   flux describe kustomization <name> -n <namespace>
   flux reconcile kustomization <name> -n <namespace> --with-source
   ```

2. **HelmRelease failing**:
   ```bash
   flux describe helmrelease <name> -n <namespace>
   kubectl logs -n flux-system deployment/helm-controller | tail -100
   ```

3. **Secret injection issues**:
   ```bash
   # Check if secret exists
   kubectl get secret <secret-name> -n <namespace>
   
   # Test secret decryption
   sops -d secrets/production/<file>.yaml > /dev/null && echo "OK"
   ```

4. **Flux reconciliation slow**:
   - Controllers are configured with `--concurrent=20`
   - Check for resource constraints: `kubectl top pods -n flux-system`
   - Verify network connectivity to source repositories

For comprehensive troubleshooting, see `.opencode/context/core/workflows/troubleshoot-flux.md`.

## Agent Guidance

### OpenCode Standards Reference
This repository uses OpenCode standards for consistent agent interactions:

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

### Core Agent Rules for Flux Operations
1. **When asked about Kubernetes operations, always check this file (`flux/AGENTS.md`) first.**
2. **When working with Kubernetes operations, unless otherwise specified, use the default Kubernetes context.**
3. **For app-specific questions, first check the app's directory structure in `apps/base/`.**
4. **New secrets should follow the pattern: `<app>-secrets-flux.yaml`.**
5. **Always run validation before committing changes: `./scripts/validate.sh`.**
6. **Use pattern-based app discovery instead of maintaining app lists:**
   ```bash
   ls /home/zshen/personal/server-config/flux/apps/base/
   ```

### Agent Examples

**Example 1: User asks "How do I deploy a new application?"**
1. Reference this file (Rule 1)
2. Follow `deploy-new-app.md` workflow
3. Use secret naming pattern (Rule 4)
4. Validate before committing (Rule 5)

**Example 2: User asks "What applications are running?"**
1. Use app discovery (Rule 6): `ls flux/apps/base/`
2. Check for secret patterns
3. Reference appropriate documentation

**Example 3: User asks "Update cert-manager version"**
1. Check this file (Rule 1)
2. Use default Kubernetes context (Rule 2)
3. Validate changes (Rule 5)

## Reference Documentation

- **Base AGENTS.md**: `/home/zshen/personal/server-config/AGENTS.md` (NixOS/host configuration)
- **OpenCode Index**: `.opencode/context/index.md`
- **Domain Context**: `.opencode/context/domain/server-config.md`
- **Flux Documentation**: https://fluxcd.io/flux/
- **Upgrade Guide**: https://fluxcd.io/flux/installation/upgrade/