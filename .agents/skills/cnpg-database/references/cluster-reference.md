# Server-config CNPG Cluster Reference

This repo models app databases as app-local CNPG cluster HelmReleases.

## Cluster File Shape

Path for new multi-tier apps:

```text
flux/apps/base/<app>/db/Cluster.yaml
```

Resource shape:

```yaml
apiVersion: helm.toolkit.fluxcd.io/v2
kind: HelmRelease
metadata:
  name: <app>-cnpg-cluster
  namespace: <app>
spec:
  chart:
    spec:
      chart: cluster
      sourceRef:
        kind: HelmRepository
        name: cnpg
        namespace: cnpg-system
  values:
    type: postgresql
    version:
      postgresql: "17"
    mode: standalone
    cluster:
      instances: 2
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

## Existing Examples

- `flux/apps/base/authentik/db/Cluster.yaml` — standard db tier.
- `flux/apps/base/n8n/db/Cluster.yaml` — extra roles/databases.
- `flux/apps/base/dify/Cluster.yaml` — legacy root-level layout; do not copy for new apps unless matching legacy intentionally.

## Generated Resources

The chart renders a CNPG `postgresql.cnpg.io/v1 Cluster` named `<app>-cnpg-cluster`.

CNPG creates Secret `<app>-cnpg-cluster-app` with keys:

- `user`
- `password`
- `host`
- `dbname`
- `port`

## Production Health Check

Add a health check to `flux/clusters/production/apps-db.yaml`:

```yaml
- apiVersion: postgresql.cnpg.io/v1
  kind: Cluster
  name: <app>-cnpg-cluster
  namespace: <app>
```
