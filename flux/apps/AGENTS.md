# flux/apps

> App overlay ownership and onboarding notes. Parent `flux/AGENTS.md` owns Flux-wide rules; `base/AGENTS.md` owns base manifest patterns.

## Overview
- `apps/` is the app deployment layer below Flux cluster entrypoints.
- Base app manifests live under `base/`; overlays select which bases Flux reconciles.
- Production is mid-split: legacy monolith still exists while DB/nonDB owners take over.
- Staging is podinfo-focused and not a production app template.

## Structure
```
apps/
├── base/                  # per-app manifests; see base/AGENTS.md
├── production/            # legacy monolithic production overlay
├── production-db/         # CNPG database resources for split production owner
├── production-nondb/      # app/runtime resources for split production owner
└── staging/               # podinfo-oriented staging overlay
```

## Where to Look
| Need | Path | Notes |
|------|------|-------|
| Add production app | `production-nondb/kustomization.yaml` | Default target for non-DB app resources. |
| Add CNPG database | `production-db/kustomization.yaml` | Only `base/<app>/db` entries. |
| Legacy ownership check | `production/kustomization.yaml` | Monolithic owner; keep in sync during split. |
| Staging sample | `staging/` | Podinfo only; do not infer production shape. |
| Flux owner wiring | `../clusters/production/apps*.yaml` | `apps`, `apps-db`, `apps-nondb` Kustomizations. |
| App manifest details | `base/AGENTS.md` | Do not duplicate those rules here. |

## Overlay Rules
- `production/` is legacy monolithic owner with `prune: false` in `clusters/production/apps.yaml`.
- `production-db/` is owned by `apps-db`; includes CNPG apps: `authentik`, `freshrss`, `langfuse`, `litellm`, `n8n`.
- `production-nondb/` is owned by `apps-nondb`; depends on `apps-db` and contains simple apps plus `base/<app>/app` tiers.
- Keep split app paths tiered: DB resources in `base/<app>/db`, runtime resources in `base/<app>/app`.
- Add simple non-CNPG apps directly as `../base/<app>` in `production-nondb/`.
- While the split is active, update `production/` only when needed to avoid ownership drift.
- Do not remove a resource from a live owner unless the replacement owner is reconciled and healthy.

## App Onboarding Checklist
1. Read `flux/AGENTS.md`, then `base/AGENTS.md` before editing app manifests.
2. Create or update the app under `base/<app>/` using base-local patterns.
3. For CNPG apps, expose `base/<app>/db` and `base/<app>/app` tiers.
4. Add DB tier to `production-db/kustomization.yaml` only if the app owns a CNPG `Cluster`.
5. Add runtime tier or simple app to `production-nondb/kustomization.yaml`.
6. Consider whether legacy `production/kustomization.yaml` must stay aligned during migration.
7. If adding a CNPG cluster, update `clusters/production/apps-db.yaml` health checks.
8. Run local checks from repo root: `./flux/scripts/validate.sh`.

## Always
- Preserve `prune: false` on production app owners unless explicitly migrating ownership.
- Keep `apps-nondb` dependent on `apps-db` for DB-backed apps.
- Use `./flux/` paths in cluster Kustomizations.
- Prefer pattern discovery over hand-maintained app inventories.
- Keep overlay diffs small: resource list changes only unless ownership changes are requested.

## Ask First
- Retiring or suspending the legacy `apps` production owner.
- Enabling `prune: true` for any production app owner.
- Moving an app between DB/nonDB ownership models.
- Adding live-cluster actions beyond validation or read-only status checks.
- Treating staging as a real production-like environment.

## Never
- Put base manifest design rules here; they belong in `base/AGENTS.md`.
- Use `staging/` as the template for production onboarding.
- Mix CNPG `Cluster` resources into `production-nondb/`.
- Add app runtime resources to `production-db/`.
- Delete legacy `production/` entries as cleanup without an explicit migration plan.
- Edit generated Flux files under `clusters/*/flux-system/`.

## Gotchas
- `production/` and split overlays can reference the same app during migration; ownership changes need care.
- `apps-db` has explicit CNPG health checks; adding a DB app without one can make readiness misleading.
- `apps-nondb` waits on all DB health, so one failing CNPG cluster can block app rollout.
- Some base apps are present but commented out or not selected by production overlays.
- Staging currently patches podinfo values only; it is not evidence that an app is production-ready.
