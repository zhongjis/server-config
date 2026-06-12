---
name: cnpg-database
description: |
  CloudNativePG (CNPG) PostgreSQL database management for this server-config Flux repo.
  Covers app-local CNPG clusters, Flux split DB/app ownership, CNPG-generated app
  credentials, HelmRelease valuesFrom wiring, and production health checks.

  Use when: (1) Adding or changing a PostgreSQL database for an application, (2) Creating
  a CNPG-backed app split into db/app tiers, (3) Debugging CNPG cluster readiness or app DB
  connectivity, (4) Wiring CNPG-generated credentials into HelmRelease values, (5) Adding
  app-specific CNPG roles/databases.

  Triggers: "database", "postgresql", "postgres", "cnpg", "cloudnativepg", "cloudnative-pg",
  "CloudNativePG", "database cluster", "cnpg cluster", "<app>-cnpg-cluster",
  "<app>-cnpg-cluster-app", "apps-db", "production-db"
user-invocable: false
upstream: "https://github.com/ionfury/homelab/tree/main/.claude/skills/cnpg-database"
---

# CNPG Database Management

## Repo Pattern

This repo does **not** use a shared platform CNPG cluster or per-app `Database` CRs as the default pattern. CNPG-backed apps own dedicated app-local clusters.

- Base manifests live under `flux/apps/base/<app>/`.
- New multi-tier CNPG apps should use:
  - `flux/apps/base/<app>/db/` for namespace + CNPG cluster HelmRelease
  - `flux/apps/base/<app>/app/` for app chart source + app HelmRelease
  - parent `flux/apps/base/<app>/kustomization.yaml` listing `./db` then `./app`
- Cluster file name stays `Cluster.yaml`, but it is a Flux `HelmRelease` for CNPG chart `cluster`, not a raw `postgresql.cnpg.io/v1 Cluster` manifest.
- Cluster HelmRelease name: `<app>-cnpg-cluster`.
- CNPG-generated Secret: `<app>-cnpg-cluster-app`.
- App HelmRelease uses `dependsOn` for `<app>-cnpg-cluster` before reading DB credentials.

Reference examples:

- `flux/apps/base/authentik/db/Cluster.yaml`
- `flux/apps/base/authentik/app/HelmRelease.yaml`
- `flux/apps/base/n8n/db/Cluster.yaml` for extra `roles` + `databases`
- `flux/apps/base/AGENTS.md` for base app conventions
- `flux/apps/AGENTS.md` for production overlay ownership

## Workflow: Add CNPG Database for New App

1. Read `flux/AGENTS.md`, `flux/apps/AGENTS.md`, and `flux/apps/base/AGENTS.md`.
2. Create `flux/apps/base/<app>/db/` with `Namespace.yaml`, `Cluster.yaml`, and `kustomization.yaml`.
3. Create `flux/apps/base/<app>/app/` with chart source and `HelmRelease.yaml`.
4. In app `HelmRelease.yaml`:
   - add `dependsOn: [{ name: <app>-cnpg-cluster }]`
   - read CNPG-generated Secret `<app>-cnpg-cluster-app` via `valuesFrom`
   - use Secret keys `user`, `password`, `host`, `dbname`, and `port` as required by the chart
5. Add DB tier to `flux/apps/production-db/kustomization.yaml` only if app owns CNPG.
6. Add runtime tier to `flux/apps/production-nondb/kustomization.yaml`.
7. Add production Flux health check for the generated CNPG `Cluster` in `flux/clusters/production/apps-db.yaml`.
8. Run `./flux/scripts/validate.sh` from repo root.

## Cluster HelmRelease Template

```yaml
---
# yaml-language-server: $schema=https://raw.githubusercontent.com/fluxcd-community/flux2-schemas/refs/heads/main/all.json
apiVersion: helm.toolkit.fluxcd.io/v2
kind: HelmRelease
metadata:
  name: <app>-cnpg-cluster
  namespace: <app>
spec:
  interval: 30m
  chart:
    spec:
      chart: cluster
      version: 0.5.0
      sourceRef:
        kind: HelmRepository
        name: cnpg
        namespace: cnpg-system
      interval: 12h
  values:
    type: postgresql
    version:
      postgresql: "17"
    mode: standalone
    cluster:
      instances: 2
      affinity:
        topologyKey: kubernetes.io/hostname
      storage:
        size: 5Gi
        storageClass: "longhorn"
      initdb:
        database: <app>
        owner: <app>_user
      monitoring:
        enabled: true
        podMonitorEnabled: true
```

## App HelmRelease Credential Wiring

Use the generated Secret from the same namespace:

```yaml
spec:
  dependsOn:
    - name: <app>-cnpg-cluster
  valuesFrom:
    - kind: Secret
      name: <app>-cnpg-cluster-app
      valuesKey: user
      targetPath: path.to.db.user
    - kind: Secret
      name: <app>-cnpg-cluster-app
      valuesKey: password
      targetPath: path.to.db.password
    - kind: Secret
      name: <app>-cnpg-cluster-app
      valuesKey: host
      targetPath: path.to.db.host
    - kind: Secret
      name: <app>-cnpg-cluster-app
      valuesKey: dbname
      targetPath: path.to.db.name
    - kind: Secret
      name: <app>-cnpg-cluster-app
      valuesKey: port
      targetPath: path.to.db.port
```

Match `targetPath` to the chart. Existing charts differ.

## Extra Roles / Databases

Some apps need more roles or DBs under the same CNPG cluster. Follow `flux/apps/base/n8n/db/Cluster.yaml`:

```yaml
values:
  cluster:
    roles:
      - name: <role>_user
        login: true
        passwordSecret:
          name: <existing-sops-secret>
  databases:
    - name: <database>
      owner: <role>_user
```

Do not create plaintext Secrets. App-input Secrets belong in `flux/secrets/production/` as SOPS-encrypted manifests; CNPG-generated app secrets are created by operator and are not stored there.

## Production Ownership Checklist

- `flux/apps/production-db/kustomization.yaml`: add `../base/<app>/db`.
- `flux/apps/production-nondb/kustomization.yaml`: add `../base/<app>/app`.
- `flux/clusters/production/apps-db.yaml`: add health check:

```yaml
- apiVersion: postgresql.cnpg.io/v1
  kind: Cluster
  name: <app>-cnpg-cluster
  namespace: <app>
```

Keep `production-db` DB-only and `production-nondb` runtime-only.

## Debugging

Read-only checks first:

```bash
flux get kustomizations
flux get helmreleases --all-namespaces
kubectl get cluster -A
kubectl describe cluster -n <app> <app>-cnpg-cluster
kubectl get secret -n <app> <app>-cnpg-cluster-app
kubectl logs -n cnpg-system deploy/cnpg-cloudnative-pg
```

Common issues:

| Symptom | Cause | Fix |
|---------|-------|-----|
| `apps-nondb` blocked | `apps-db` not healthy | Inspect failing CNPG health check in `flux/clusters/production/apps-db.yaml` |
| App starts before DB | Missing HelmRelease `dependsOn` | Add `dependsOn` to app HelmRelease |
| App cannot read credentials | Wrong Secret name or key | Use `<app>-cnpg-cluster-app` keys: `user`, `password`, `host`, `dbname`, `port` |
| CNPG cluster not created | DB tier not selected | Add `../base/<app>/db` to `production-db/kustomization.yaml` |
| Runtime deployed without DB | Runtime added to wrong overlay | Keep CNPG DB in `production-db`; app in `production-nondb` |

## Validation

Run from repo root:

```bash
./flux/scripts/validate.sh
```

If `kubeconform` is missing:

```bash
nix shell nixpkgs#kubeconform -c ./flux/scripts/validate.sh
```

## Vendored References

Files under `references/` and `scripts/` come from upstream and may describe a different homelab pattern. Treat this `SKILL.md` as authoritative for this repo.
