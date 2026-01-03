# Agent Rules & Guidelines

## Repository Context

This repository has a **two-part architecture**:
1. **NixOS Host Configuration** (base directory) - Managed via base `AGENTS.md`
2. **FluxCD GitOps Configuration** (`flux/` subdirectory) - Managed via `flux/AGENTS.md`

## Core Rules

### 1. Context Selection Rule
**When asked about Kubernetes operations, always check `flux/AGENTS.md` first.**

Examples:
- "Deploy a new application" → Check `flux/AGENTS.md`
- "Check cluster status" → Check `flux/AGENTS.md`  
- "Update Flux components" → Check `flux/AGENTS.md`

### 2. Kubernetes Context Rule
**When working with Kubernetes operations, unless otherwise specified, use the default Kubernetes context.**

Agents should:
- Use the default context for `kubectl`, `flux`, and other Kubernetes commands
- Only specify alternative contexts when explicitly requested
- Document which context is being used in command outputs

### 3. File Path Convention Rule
**Always use absolute paths or correctly prefixed relative paths.**

For Flux operations, paths use `./flux/` prefix:
- Correct: `./flux/apps/production`
- Correct: `./flux/infrastructure/controllers`
- Incorrect: `apps/production` (missing `./flux/` prefix)

### 4. Secret Naming Pattern Rule
**New secrets should follow the pattern: `<app>-secrets-flux.yaml`**

Pattern hierarchy:
1. **Preferred (new)**: `<app>-secrets-flux.yaml`
2. **Legacy**: `<app>-secrets-fluxcd.yaml`
3. **Legacy**: `<app>-secrets.yaml`

Examples:
- `n8n-secrets-flux.yaml` (preferred for new apps)
- `actualbudget-secrets-fluxcd.yaml` (existing legacy)
- `redis-secrets.yaml` (existing legacy)

### 5. App Discovery Rule
**For app-specific questions, first check the app's directory structure in `flux/apps/base/`**

Pattern:
```
flux/apps/base/<app-name>/
├── Namespace.yaml
├── HelmRepo.yaml or OCIRepository.yaml
├── HelmRelease.yaml
├── kustomization.yaml
└── (optional) Cluster.yaml, GrafanaDashboard.yaml
```

Instead of maintaining app lists in documentation, use:
```bash
ls /home/zshen/personal/server-config/flux/apps/base/
```

### 6. Source Type Recognition Rule
**Recognize different source types for Helm charts:**

1. **HelmRepo.yaml** - External Helm repository
2. **OCIRepository.yaml** - OCI-based Helm charts (e.g., from Docker registry)

Both serve the same purpose: providing Helm charts to `HelmRelease.yaml`.

### 7. Database Pattern Rule
**Applications with PostgreSQL use CloudNativePG `Cluster.yaml`**

Pattern:
- App directory contains `Cluster.yaml` for PostgreSQL
- `HelmRelease.yaml` uses `dependsOn` to wait for database cluster
- Database credentials from auto-generated secrets (`<app>-cnpg-cluster-app`)

### 8. Validation Rule
**Always run validation before committing changes:**

```bash
./flux/scripts/validate.sh
```

This validates:
- YAML syntax
- Flux Kustomizations and HelmReleases
- All kustomize overlays

### 9. Secret Management Rule
**Always encrypt secrets with SOPS before committing:**

```bash
sops --age=age1gff6wle45ktarxc89vfqnq6qawwjcxd5jed4jnuhhddpeqxz6d7q8wq8gn \
  --encrypt --encrypted-regex '^(data|stringData)$' --in-place <file>.yaml
```

### 10. Architecture Boundary Rule
**Respect the separation between NixOS and FluxCD responsibilities:**

| Responsibility | Location | Documentation |
|----------------|----------|---------------|
| Host configuration, k3s setup | Base directory | Base `AGENTS.md` |
| Kubernetes apps, GitOps | `flux/` directory | `flux/AGENTS.md` |

## Agent Examples

### Example 1: User asks "How do I deploy a new application?"
1. Check `flux/AGENTS.md` (Rule 1)
2. Follow patterns in `deploy-new-app.md` workflow
3. Use secret naming pattern (Rule 4)
4. Validate before committing (Rule 8)

### Example 2: User asks "What applications are running?"
1. Use app discovery (Rule 5): `ls flux/apps/base/`
2. Check for secret patterns (Rule 4)
3. Reference appropriate AGENTS.md based on context

### Example 3: User asks "Update cert-manager version"
1. Check `flux/AGENTS.md` (Rule 1)
2. Use default Kubernetes context (Rule 2)
3. Validate changes (Rule 8)

## Reference Files

- Base AGENTS.md: `/home/zshen/personal/server-config/AGENTS.md`
- Flux AGENTS.md: `/home/zshen/personal/server-config/flux/AGENTS.md`
- OpenCode Index: `.opencode/context/index.md`