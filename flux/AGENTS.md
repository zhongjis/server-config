# Flux/Kubernetes Agent Guide

## OVERVIEW
- This `flux/` tree is the Kubernetes GitOps subsystem for the server-config repo.
- Flux v2 reconciles cluster state from `clusters/`, `infrastructure/`, `apps/`, `monitoring/`, and `secrets/`.
- Keep this file focused on Kubernetes/Flux work; root NixOS and Colmena guidance lives in `../AGENTS.md`.

## STRUCTURE
```
flux/
├── clusters/          # Flux reconciliation entrypoints and dependencies
├── infrastructure/    # platform controllers and cluster-wide config
├── apps/              # application bases and production overlays
├── monitoring/        # observability controllers, dashboards, and config
├── secrets/           # SOPS-encrypted Kubernetes Secret manifests
└── scripts/           # validation and helper scripts
```

## WHERE TO LOOK
| Task | Location | Notes |
|------|----------|-------|
| Reconciliation entrypoints | `clusters/` | Flux Kustomizations, source references, dependency ordering. |
| Platform controllers/config | `infrastructure/` | cert-manager, ingress, MetalLB, storage, DNS, CNPG operator, and dependent CRs. |
| Application manifests | `apps/` | App bases plus production overlays and split app groups. |
| Observability | `monitoring/` | Prometheus/Grafana/Loki resources and dashboards. |
| Kubernetes secrets | `secrets/` | SOPS-encrypted Secret manifests; new app secrets use `<app>-secrets-flux.yaml`. |
| Validation behavior | `scripts/validate.sh` | YAML, schema, and kustomize checks used before commit. |

## COMMANDS
```bash
# Validate from flux/
./scripts/validate.sh

# Validate from repo root
./flux/scripts/validate.sh

# Flux status
flux get kustomizations
flux get helmreleases --all-namespaces
flux logs --level=error

# Reconcile source and kustomization
flux reconcile source git flux-system -n flux-system
flux reconcile kustomization <name> -n flux-system --with-source

# Reconcile HelmRelease
flux reconcile helmrelease <name> -n <namespace>

# Common local render checks
kustomize build --load-restrictor=LoadRestrictionsNone ./apps/production
kustomize build --load-restrictor=LoadRestrictionsNone ./infrastructure/controllers
```

## VALIDATION SCRIPT
- `scripts/validate.sh` downloads Flux CRD schemas before schema validation.
- It checks every YAML file with `yq`.
- It runs `kubeconform` with `-skip=Secret -strict -ignore-missing-schemas`.
- It runs `kustomize build` with `--load-restrictor=LoadRestrictionsNone`.
- Run validation before committing Kubernetes manifest changes.

## ALWAYS
- Read this file before any Kubernetes, Flux, HelmRelease, Kustomization, Secret, CNPG, or kubectl work.
- Read the child `AGENTS.md` for the subtree you are editing when one exists.
- Use the default Kubernetes context unless the user specifies a different context.
- Keep changes declarative and GitOps-managed; prefer manifests over live-only cluster edits.
- Name new app secret manifests `<app>-secrets-flux.yaml`.
- Validate with `./scripts/validate.sh` from `flux/` or `./flux/scripts/validate.sh` from repo root before commit.

## ASK FIRST
- Changing reconciliation topology, app split ownership, or `dependsOn` relationships.
- Editing generated Flux bootstrap files under `clusters/*/flux-system/`.
- Renaming namespaces, applications, HelmReleases, or Secret resources.
- Changing storage classes, ingress class behavior, DNS/TLS issuers, or production endpoints.
- Decrypting or rotating secrets, or changing SOPS creation rules.
- Running live `kubectl` mutations that are not represented in Git.

## NEVER
- Do not commit plaintext Kubernetes Secrets or decrypted SOPS output.
- Do not create ad-hoc Secret manifests outside SOPS policy.
- Do not edit `gotk-components.yaml` or `gotk-sync.yaml` directly unless explicitly regenerating Flux bootstrap output.
- Do not bypass overlays by changing only rendered output.
- Do not add references to files or workflows that are not present in this repo.
- Do not duplicate root host, NixOS, or Colmena instructions here.

## GOTCHAS
- Flux Kustomization paths are relative to the repo root, so entries commonly use `./flux/...`.
- `kubeconform` skips Kubernetes `Secret` resources because encrypted SOPS data is not valid decoded Secret data before decryption.
- Missing schemas are ignored during validation, so also inspect CRD-heavy changes with `kustomize build`.
- `--load-restrictor=LoadRestrictionsNone` is intentional for existing kustomize layouts.
- Secrets for Flux apps are separate from root NixOS secrets.
- Some app dependencies are enforced through Flux `dependsOn`; changing names can break reconciliation order.

## CHILD AGENTS.md LIST
- `flux/apps/AGENTS.md` — app overlays and app onboarding.
- `flux/apps/base/AGENTS.md` — base app manifest patterns.
- `flux/clusters/AGENTS.md` — reconciliation entrypoints and split app ownership.
- `flux/infrastructure/AGENTS.md` — platform controllers and cluster configs.
- `flux/monitoring/AGENTS.md` — observability stack.
- `flux/secrets/AGENTS.md` — Kubernetes SOPS secrets.