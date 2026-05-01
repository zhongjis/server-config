# Uptime Kuma operator notes

Uptime Kuma is deployed as a raw Kubernetes app for `https://status.zshen.me/`. Flux owns the Kubernetes resources and Homepage static widget; the Uptime Kuma application content is bootstrapped once in the UI.

## GitOps-managed configuration

Flux manages these files declaratively:

- Namespace: `uptimekuma` from `Namespace.yaml`.
- Workload: `Deployment/uptimekuma` using `louislam/uptime-kuma:2`, `Recreate` strategy, port `3001`, and `/app/data`.
- Storage: `PersistentVolumeClaim/uptimekuma-data`, Longhorn, `ReadWriteOnce`, `5Gi`.
- Network: `Service/uptimekuma` on port `3001`.
- Ingress/TLS: `Ingress/uptimekuma` for `status.zshen.me` with TLS secret `uptimekuma-tls`.
- Homepage widget: static `Uptime Kuma` service in `flux/apps/base/homepage/ConfigMap.yaml`, with widget `type: uptimekuma`, `url: https://status.zshen.me`, and `slug: default`.
- Monitor inventory: `flux/apps/base/uptimekuma/monitor-inventory.md`.

## One-time Uptime Kuma UI bootstrap

These steps are not fully GitOps-managed. Do them in the Uptime Kuma UI after Flux reconciles the app:

1. Open `https://status.zshen.me/`.
2. Create the first admin user.
3. Create and publish the status page with slug `default`.
4. Create monitors from `monitor-inventory.md`.
5. Confirm the Homepage Uptime Kuma widget renders data from the `default` status page.

Do not store Uptime Kuma admin credentials, monitor secrets, tokens, or passwords in this README or in plaintext manifests.

## Read-only post-reconcile checks

Run these checks after Flux reconciliation. They are read-only and should not mutate the cluster.

```bash
# Local render check from repo root
kustomize build --load-restrictor=LoadRestrictionsNone ./flux/apps/production-nondb

# Repository validation from repo root; direct execution requires kubeconform in PATH
./flux/scripts/validate.sh

# If kubeconform is missing locally, use an ephemeral Nix shell
nix shell nixpkgs#kubeconform -c ./flux/scripts/validate.sh

# Workload and storage
kubectl get namespace uptimekuma
kubectl get deployment,replicaset,pod,service,ingress,pvc -n uptimekuma
kubectl describe deployment uptimekuma -n uptimekuma
kubectl describe pvc uptimekuma-data -n uptimekuma

# Ingress and TLS
kubectl describe ingress uptimekuma -n uptimekuma
kubectl get secret uptimekuma-tls -n uptimekuma

# Public endpoint
curl -I https://status.zshen.me/
curl -I https://status.zshen.me/status/default
```

Homepage widget checks:

```bash
kubectl get configmap homepage -n homepage
kubectl describe configmap homepage -n homepage
curl -I https://status.zshen.me/status/default
```

Expected results: the deployment has one available replica, the PVC is bound, the ingress lists `status.zshen.me` and `uptimekuma-tls`, the public URL returns HTTP headers, and the Homepage widget has data once the `default` status page exists and is published.

## Future alert setup

When alerts are added later, keep credentials declarative and encrypted:

1. Create a SOPS-encrypted Kubernetes `Secret` under `flux/secrets/production`, preferably named `uptimekuma-secrets-flux.yaml`.
2. Encrypt `data` or `stringData` with the repo SOPS policy before commit.
3. Add the Secret to `flux/secrets/production/kustomization.yaml`.
4. Reference that Secret declaratively from future app manifests or automation.

Do not commit plaintext provider credentials, sample tokens, passwords, webhook URLs with embedded secrets, or provider-specific alert configuration in this base now.

## Monitor inventory maintenance

`monitor-inventory.md` is the source of truth for manual monitor creation. Update it whenever Homepage-visible services change:

1. Review static services in `flux/apps/base/homepage/ConfigMap.yaml`.
2. Review selected app bases for `gethomepage.dev/enabled: "true"` annotations and public URLs.
3. Add, remove, or update inventory rows so each Homepage-visible service has the intended URL and expected status rule.
4. Keep excluded infrastructure or backend-only services in the `Not monitored` table with the reason.
5. After changing the inventory, manually reconcile Uptime Kuma monitors in the UI; monitor provisioning is not fully GitOps-managed.
