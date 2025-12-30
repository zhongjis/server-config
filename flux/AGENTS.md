# Agent Guidelines for Server Config / Flux

## Directory Overview

This is a FluxCD-based GitOps repository managing a Kubernetes cluster with multiple self-hosted applications. The repository follows the Flux v2 structure with Kustomize overlays for different environments (production/staging). Flux continuously reconciles the cluster state with this Git repository.

## Repository Structure

The repository follows a three-tier structure:

1. **clusters/** - Flux configuration entry points
   - `clusters/production/` - Production cluster Flux Kustomizations
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
- `HelmRepo.yaml` - Defines the Helm repository source
- `HelmRelease.yaml` - Main deployment with values configuration
- `kustomization.yaml` - Lists all resources
- Optional: `GrafanaDashboard.yaml`, CloudNativePG `Cluster.yaml`

### Secret Management

Secrets are managed using SOPS with age encryption:

- Encrypted secrets live in `secrets/production/`
- HelmReleases reference secrets via `valuesFrom` to inject values into Helm charts
- Secrets follow naming pattern: `<app>-secrets-fluxcd.yaml` or `<app>-secrets.yaml`
- Encryption command from README: `sops --age=age1gff6wle45ktarxc89vfqnq6qawwjcxd5jed4jnuhhddpeqxz6d7q8wq8gn --encrypt --encrypted-regex '^(data|stringData)$' --in-place <file>.yaml`

### Environment-Specific Configuration

Production uses JSON patches in `clusters/production/infrastructure.yaml`:

- Example: Replaces Let's Encrypt staging server with production server for ClusterIssuer
- Patches applied at the Flux Kustomization level, not in app manifests

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

1. Define HelmRepository source
2. Create HelmRelease with chart version pinned
3. Use `valuesFrom` to inject secrets from Kubernetes Secrets
4. Configure ingress, persistence (usually Longhorn), and resource limits

### Applications with CloudNativePG

Apps requiring PostgreSQL (freshrss, n8n) use CloudNativePG operator:

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

## Important Notes

### Version Pinning

All HelmReleases specify exact chart versions (e.g., `version: 1.16.14`), not semver ranges. This ensures predictable deployments and requires manual version updates.

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
2. Add manifests: Namespace, HelmRepo, HelmRelease, kustomization
3. If secrets needed, create encrypted secret in `secrets/production/`
4. Reference secret in HelmRelease via `valuesFrom`
5. Add app to `apps/production/kustomization.yaml` resources list
6. Run `./scripts/validate.sh` to validate
7. Commit and push - Flux will reconcile automatically
