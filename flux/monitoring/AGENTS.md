# flux/monitoring

> Observability stack notes. Parent `flux/AGENTS.md` owns Flux-wide rules; this file covers monitoring-specific resources only.

## Overview
- `monitoring/` owns the cluster observability stack: Prometheus, Grafana, Loki, Tempo, dashboards, and stack-local config.
- Controllers live under `controllers/` and render into the `monitoring` namespace.
- Config-only resources live under `configs/`, mainly Grafana dashboard ConfigMaps.
- The `monitoring` Namespace intentionally enforces `pod-security.kubernetes.io/enforce: privileged` for this stack.

## Structure
```
monitoring/
├── controllers/
│   ├── Namespace.yaml
│   ├── HelmRepo.yaml
│   ├── kube-prometheus-stack/  # Prometheus, Grafana, exporters, rules
│   ├── loki/                   # log storage/query stack
│   ├── tempo/                  # tracing stack
│   └── alloy/                  # present but commented out in kustomization.yaml
└── configs/
    ├── dashboards/             # Grafana dashboard JSON
    └── kustomization.yaml      # dashboard ConfigMap generators
```

## Where to Look
| Need | Path | Notes |
|------|------|-------|
| Namespace and enabled stacks | `controllers/kustomization.yaml` | Includes namespace, shared Helm repo, Prometheus, Loki, Tempo; Alloy is commented. |
| Monitoring namespace policy | `controllers/Namespace.yaml` | Pod Security enforce level is `privileged`. |
| Prometheus/Grafana values | `controllers/kube-prometheus-stack/HelmRelease.yaml` | Helm values, OAuth, scrape selectors, node endpoint IPs, drift ignore. |
| Grafana/Loki repo source | `controllers/HelmRepo.yaml` | Shared HelmRepository for Grafana charts. |
| Prometheus chart source | `controllers/kube-prometheus-stack/HelmRepo.yaml` | prometheus-community HelmRepository. |
| Loki storage/retention/resources | `controllers/loki/HelmRelease.yaml` | S3/minio-style backend and stack-local sizing. |
| Tempo values | `controllers/tempo/HelmRelease.yaml` | Trace storage and deployment config. |
| Dashboard ConfigMaps | `configs/kustomization.yaml`, `configs/dashboards/` | Add dashboard JSON and include it in the generator. |

## ServiceMonitor Conventions
- Prometheus uses explicit selectors from kube-prometheus-stack values; app ServiceMonitors must carry `release: prometheus`.
- Preserve any app-specific labels such as `team` or target labels when editing existing ServiceMonitors.
- Match the endpoint port name used by the app Service; do not invent a new port solely for scraping.
- For Helm charts that generate ServiceMonitors, set labels through chart values rather than patching rendered objects when possible.

## Dashboard Conventions
- Put dashboard JSON under `configs/dashboards/`.
- Add new dashboard files to `configs/kustomization.yaml` under `configMapGenerator.files`.
- Keep generated dashboard ConfigMaps labeled with `grafana_dashboard: "1"` so Grafana sidecar discovery can load them.
- Keep `kustomize.toolkit.fluxcd.io/substitute: disabled` on dashboard ConfigMaps unless the JSON intentionally uses Flux substitution.

## Gotchas
- Grafana OAuth and admin credentials come from the `monitoring-secrets` Secret; do not inline these values in HelmRelease manifests.
- kube-prometheus-stack drift detection intentionally ignores `/metadata/annotations/prometheus-operator-validated` on `PrometheusRule` resources.
- Prometheus control-plane scrape endpoints hardcode node IPs `192.168.50.103`, `192.168.50.104`, and `192.168.50.105`; update them when k3s nodes change.
- Loki uses an S3/minio-style backend from its Helm values; retention and resource settings are local to this stack.
- Alloy manifests exist but are not reconciled while `./alloy` remains commented in `controllers/kustomization.yaml`.

## Commands
```bash
# Render monitoring controllers
kustomize build --load-restrictor=LoadRestrictionsNone ./flux/monitoring/controllers

# Render monitoring config/dashboard resources
kustomize build --load-restrictor=LoadRestrictionsNone ./flux/monitoring/configs

# Full Flux validation from repo root
./flux/scripts/validate.sh

# Live read-only checks
flux get helmreleases -n monitoring
kubectl get servicemonitors,podmonitors,prometheusrules -n monitoring
kubectl get configmaps -n monitoring -l grafana_dashboard=1
```
