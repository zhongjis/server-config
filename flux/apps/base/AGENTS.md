# flux/apps/base

Guidance for base application manifests under `flux/apps/base/`. Keep this file focused on base resources only; environment overlays decide which bases are enabled.

## Scope
- Contains 20 app bases: `actualbudget`, `authentik`, `capacitor`, `cloudflared`, `dify`, `freshrss`, `home-assistant`, `homepage`, `karakeep`, `langfuse`, `litellm`, `manyfold`, `minio`, `mlflow`, `mongodb`, `n8n`, `open-webui`, `redis`, `stirling-pdf`, `supabase`.
- Use this directory for reusable app manifests: Namespaces, Flux sources, HelmReleases, CNPG database definitions, and app-local raw manifests.
- Do not put production/staging selection rules here; overlays own inclusion and environment-specific patches.

## Where to Look
- Standard single-tier Helm app: `actualbudget/`, `home-assistant/`, `karakeep/`, `manyfold/`, `open-webui/`, `stirling-pdf/`, `supabase/`.
- OCI source examples: `mongodb/OCIRepository.yaml`, `redis/OCIRepository.yaml`.
- Multi-tier CNPG examples: `authentik/`, `langfuse/`, `litellm/`, `n8n/` with parent `kustomization.yaml` loading `./db` then `./app`.
- Legacy or transitional CNPG layouts: `dify/`, `freshrss/`, `mlflow/` may still keep root-level `Cluster.yaml` and HelmRelease files.
- Raw manifest exceptions: `homepage/` and `cloudflared/`.

## Standard Files
- `Namespace.yaml` creates the namespace for the app or component.
- `HelmRepo.yaml` or `OCIRepository.yaml` defines the chart source.
- `HelmRelease.yaml` pins and configures the deployment.
- `kustomization.yaml` lists only local resources or child directories.
- Optional app-local files include `GrafanaDashboard.yaml`, CNPG `Cluster.yaml`, or raw Kubernetes resources when the app is an exception.

## Structure Patterns
- Standard Helm app `kustomization.yaml` lists `./Namespace.yaml`, `./HelmRepo.yaml` or `./OCIRepository.yaml`, and `./HelmRelease.yaml`.
- Multi-tier app parent lists `./db` and `./app`; `db/` owns namespace plus CNPG cluster, `app/` owns chart source and HelmRelease.
- Keep resource filenames stable and PascalCase where existing apps do (`Namespace.yaml`, `HelmRelease.yaml`, `Cluster.yaml`).
- Keep app namespaces aligned with app names unless an existing chart or component already uses a different namespace.

## CNPG Pattern
- CNPG-backed apps define a `Cluster` named `<app>-cnpg-cluster` in the app namespace.
- App HelmRelease uses `dependsOn` for `<app>-cnpg-cluster` before reading DB credentials.
- Use the CNPG-generated secret `<app>-cnpg-cluster-app` for `user`, `password`, `host`, `dbname`, and `port` values.
- Put database manifests under `db/` for new multi-tier work unless matching a legacy app layout intentionally.

## Exceptions
- `homepage/` is full raw Kubernetes resources, including `Secret.yaml`; do not force Helm structure onto it.
- `cloudflared/` is a namespace plus one raw manifest.
- `n8n/` includes `HelmReleaseLegacy.yaml` and optional `langfuse-shipper/`; parent currently comments the shipper out.
- `dify/` includes `Cluster.bkp.yaml`; preserve it unless explicitly asked to clean legacy backups.
- `minio/operator` and `minio/tenant` are separate bases and are disabled in production today.
- `mongodb/HelmRelease.yaml` has a FIXME noting single-user secrets never works; do not assume that auth pattern is safe.

## Always
- Read the nearest existing app before adding or changing a base manifest.
- Keep chart versions pinned and values local to the app HelmRelease.
- Use `redis-master.redis.svc.cluster.local` for shared Redis references; confirm whether the chart expects `redis-password` or `redis-user-password`.
- Run `./flux/scripts/validate.sh` from the repo root after manifest changes when tooling is available.

## Ask First
- Moving an app between standard and multi-tier layout.
- Deleting legacy root-level CNPG files, backup files, or disabled optional components.
- Changing shared dependency names, namespaces, or generated secret assumptions.

## Never
- Do not add new plaintext `Secret.yaml` files under app dirs; discuss before touching existing raw-secret exceptions.
- Do not edit generated Flux system manifests from here.
- Do not enable disabled bases or optional subcomponents as part of base-only cleanup.

## Gotchas
- Some apps are transitional and may contain both root-level and split `db`/`app` files; match the active `kustomization.yaml`.
- Redis secret key names vary by chart even when the hostname is shared.
- `minio/tenant` intentionally reuses the operator chart source namespace rather than defining its own HelmRepo.
