# flux/infrastructure

> Platform controller and cluster-wide configuration guidance. Parent `flux/AGENTS.md` owns Flux-wide rules.

## Overview
- `infrastructure/` owns cluster platform controllers and the cluster-level resources that depend on them.
- Flux reconciles controllers first, then configs through `clusters/production/infrastructure.yaml`.
- k3s `servicelb` and `traefik` are disabled in NixOS; MetalLB and ingress-nginx here are the replacements.
- Keep this subtree focused on infrastructure controllers/configs, not application or observability details.

## Structure
```
infrastructure/
├── controllers/             # Helm-installed platform controllers
│   ├── cert-manager.yaml
│   ├── cnpg-operator.yaml
│   ├── external-dns.yaml
│   ├── ingress-nginx.yaml
│   ├── longhorn.yaml
│   ├── metallb.yaml
│   └── kustomization.yaml
└── configs/                 # CRs/config consumed by installed controllers
    ├── cluster-issuers.yaml
    ├── coredns-custom.yaml
    ├── metallb-pools.yaml
    └── kustomization.yaml
```

## Where to Look
| Need | Path | Notes |
|------|------|-------|
| Controller install | `controllers/*.yaml` | Namespace + HelmRepository + HelmRelease per controller. |
| Controller resource list | `controllers/kustomization.yaml` | Add new controller YAML here. |
| Cluster issuers | `configs/cluster-issuers.yaml` | Staging/default issuer config; production patch changes ACME server. |
| CoreDNS customization | `configs/coredns-custom.yaml` | Cluster DNS ConfigMap customizations. |
| MetalLB pools | `configs/metallb-pools.yaml` | Address pools and advertisements for service IPs. |
| Config resource list | `configs/kustomization.yaml` | Add dependent controller CRs/config here. |
| Reconcile wiring | `../clusters/production/infrastructure.yaml` | `infra-configs` depends on `infra-controllers`. |

## Controller / Config Boundary
- Put Helm controller installation resources in `controllers/` only.
- Keep the controller file shape as `Namespace`, `HelmRepository`, then `HelmRelease`.
- Put resources that require installed CRDs or controllers in `configs/`.
- Do not move CRD-backed resources into `controllers/`; Flux applies configs after controllers are ready.
- Preserve the cluster Kustomization dependency: `infra-configs` must depend on `infra-controllers`.

## Version and CRD Rules
- Pin chart versions in each `HelmRelease`; do not rely on floating chart versions.
- When bumping controller charts, read the chart release notes for CRD and value changes.
- Enable CRD install/upgrade values where the chart supports them, especially cert-manager and CNPG-style operators.
- Do not hand-copy generated CRDs into this tree unless an upstream chart cannot manage them and the change is explicit.
- For CRD schema changes, validate both `controllers/` and `configs/` because configs may fail only after CRDs change.

## Gotchas
- `clusters/production/infrastructure.yaml` patches `ClusterIssuer/cloudflare-issuer` to the Let's Encrypt production ACME server.
- Local `configs/cluster-issuers.yaml` may not show the final production ACME endpoint by itself.
- MetalLB and ingress-nginx are tied to the NixOS choice to disable k3s `servicelb` and `traefik`.
- CRD-backed config can fail if a controller chart stops installing or upgrading CRDs.
- Some validation uses `--load-restrictor=LoadRestrictionsNone`; keep commands consistent with existing repo checks.

## Commands
```bash
# Full Flux validation from repo root
./flux/scripts/validate.sh

# Render infrastructure controllers/configs locally
kustomize build --load-restrictor=LoadRestrictionsNone ./flux/infrastructure/controllers
kustomize build --load-restrictor=LoadRestrictionsNone ./flux/infrastructure/configs

# Inspect reconciliation status
flux get kustomizations -n flux-system | grep infra
flux get helmreleases --all-namespaces

# Reconcile infrastructure owners
flux reconcile kustomization infra-controllers -n flux-system --with-source
flux reconcile kustomization infra-configs -n flux-system --with-source
```
