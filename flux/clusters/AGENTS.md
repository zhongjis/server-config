# flux/clusters

> Flux reconciliation entrypoints for production and staging clusters.

## Overview

- Owns top-level Flux `Kustomization` entrypoints; `spec.path` values keep the `./flux/...` prefix because the Git source root is repo root.
- `production/` is split into infrastructure, monitoring, legacy apps, database apps, and non-database apps.
- `staging/` is smaller and currently reconciles infrastructure plus the staging app overlay.

## Where to Look

| Need | File or directory | Notes |
|------|-------------------|-------|
| Production Flux bootstrap | `production/flux-system/` | Generated Flux install and sync manifests. |
| Production infrastructure entrypoint | `production/infrastructure.yaml` | Defines controller/config reconciliation ordering. |
| Production monitoring entrypoint | `production/monitoring.yaml` | Monitoring stack entrypoint. |
| Production legacy app owner | `production/apps.yaml` | Monolithic app owner retained during split. |
| Production DB app owner | `production/apps-db.yaml` | DB-backed app split owner with CNPG health checks. |
| Production non-DB app owner | `production/apps-nondb.yaml` | Depends on DB app split being healthy. |
| Staging Flux bootstrap | `staging/flux-system/` | Generated Flux install and sync manifests. |
| Staging infrastructure entrypoint | `staging/infrastructure.yaml` | Staging infrastructure entrypoint. |
| Staging app entrypoint | `staging/apps.yaml` | Staging app overlay entrypoint. |

## Ownership / Split Rules

- Production infrastructure order is `infra-controllers` before `infra-configs`.
- Production `apps` depends on `infra-configs`.
- Production `apps-db` depends on `infra-configs` and health-checks CNPG `Cluster` resources.
- Production `apps-nondb` depends on `apps-db`.
- `production/apps.yaml` is the legacy monolithic owner while the app split is in progress.
- Do not remove ownership from `./flux/apps/production` until `apps-db` and `apps-nondb` are healthy.
- Suspend the legacy `apps` Kustomization before removing resources from its ownership.
- Keep legacy `apps` pruning disabled during the split (`prune: false`).

## Generated Manifest Anti-Patterns

- Do not hand-edit `gotk-components.yaml`.
- Do not hand-edit `gotk-sync.yaml`.
- Regenerate Flux bootstrap manifests with the Flux CLI when they need to change.
- Do not add app, infrastructure, or monitoring child resources directly under `flux-system/`.
- Do not remove the `./flux/` path prefix from Kustomization `spec.path` values.

## Commands

```bash
# Validate Flux manifests from the repository root
./flux/scripts/validate.sh

# Inspect declared entrypoints in Git
find ./flux/clusters -maxdepth 2 -type f -name '*.yaml' | sort

# Inspect live reconciliation
flux get kustomizations -A
flux describe kustomization <name> -n flux-system

# Reconcile an entrypoint after a commit is available to Flux
flux reconcile kustomization <name> -n flux-system --with-source
```

## Gotchas

- Production app ownership is intentionally duplicated during the split; change ownership in one small step at a time.
- `apps-nondb` intentionally waits for `apps-db`, so non-DB apps can be blocked by database app health.
- CNPG health checks belong to the split owner that needs database readiness, not the legacy app owner.
- The staging layout is not a complete mirror of production; do not assume production-only split files exist there.
- Generated Flux files live in both environments, but they are artifacts, not normal hand-authored manifests.
