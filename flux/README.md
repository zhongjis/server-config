# Flux GitOps manifests

Repo-specific Flux manifests for the homelab production cluster. The generated Flux bootstrap files live under `clusters/*/flux-system/`; do not edit them by hand.

## Layout

| Path | Purpose |
|------|---------|
| `apps/base/` | Reusable app manifests, HelmReleases, CNPG clusters, and app-local resources. |
| `apps/production/` | Legacy production app owner kept during ownership split. |
| `apps/production-db/` | CNPG database tiers reconciled by `apps-db`. |
| `apps/production-nondb/` | App/runtime tiers reconciled by `apps-nondb`. |
| `clusters/production/` | Flux reconciliation entrypoints for production. |
| `infrastructure/controllers/` | Platform controllers such as ingress, cert-manager, CNPG, monitoring, and Flux add-ons. |
| `infrastructure/configs/` | Controller configuration and cluster-level infrastructure resources. |
| `monitoring/` | Observability resources. |
| `secrets/` | SOPS-encrypted Kubernetes secrets. |

## Production ownership

- `clusters/production/apps.yaml` owns the legacy `apps/production` overlay with `prune: false`.
- `clusters/production/apps-db.yaml` owns `apps/production-db` and waits on CNPG cluster health checks.
- `clusters/production/apps-nondb.yaml` owns `apps/production-nondb` and depends on `apps-db`.
- Do not remove resources from a live owner unless the replacement owner is reconciled and healthy.

## Validation

Run from the repository root:

```bash
./flux/scripts/validate.sh
kustomize build --load-restrictor=LoadRestrictionsNone ./flux/apps/production-db
kustomize build --load-restrictor=LoadRestrictionsNone ./flux/apps/production-nondb
```

If `kubeconform` is missing locally:

```bash
nix shell nixpkgs#kubeconform -c ./flux/scripts/validate.sh
```

## More guidance

Read nearest `AGENTS.md` before editing:

- `flux/AGENTS.md` for Flux-wide rules.
- `flux/apps/AGENTS.md` and `flux/apps/base/AGENTS.md` for apps.
- `flux/clusters/AGENTS.md` for reconciliation entrypoints.
- `flux/infrastructure/AGENTS.md` for platform controllers/configs.
- `flux/secrets/AGENTS.md` before touching SOPS-encrypted Kubernetes secrets.
