# Update Flux Components Workflow

This workflow guides you through updating FluxCD components in the cluster.

## Overview

Flux components (source-controller, kustomize-controller, helm-controller, notification-controller) are managed via GitOps. Updates are performed by exporting the current installation and updating the manifests in the repository.

## Prerequisites

1. **Target Flux version** - Know which version you want to upgrade to
2. **Kubernetes access** - kubectl configured with cluster access
3. **Git repository access** - Ability to commit and push changes

## Current Status

### Check current Flux version
```bash
# Check Flux version in cluster
flux --version

# Check deployed components
kubectl get pods -n flux-system -l app.kubernetes.io/part-of=flux

# Check current manifests
cat ./flux/clusters/production/flux-system/gotk-components.yaml | grep "fluxcd.io/version"
```

## Step 1: Export Current Flux Installation

### 1.1 Export with target version
```bash
# Navigate to repository root
cd /home/zshen/personal/server-config

# Export Flux components (replace v2.x.x with target version)
flux install \
  --version=v2.x.x \
  --export > ./flux/clusters/production/flux-system/gotk-components.yaml
```

### 1.2 Verify exported manifest
```bash
# Check the exported file
head -50 ./flux/clusters/production/flux-system/gotk-components.yaml

# Verify version strings
grep -n "fluxcd.io/version" ./flux/clusters/production/flux-system/gotk-components.yaml
```

## Step 2: Update Performance Patches (if applicable)

### 2.1 Check current patches
The production cluster has performance patches for faster reconciliation. These should be preserved.

Check `./flux/clusters/production/infrastructure.yaml` for patches:
```yaml
patches:
  - patch: |
      - op: add
        path: /spec/interval
        value: 10m
      - op: add
        path: /spec/timeout
        value: 5m
    target:
      kind: Kustomization
  - patch: |
      - op: add
        path: /spec/interval
        value: 30m
    target:
      kind: HelmRelease
```

### 2.2 Preserve concurrency settings
Flux controllers are patched to run with `--concurrent=20` and `--requeue-dependency=5s`. Ensure these patches are maintained in the gotk-components.yaml or applied separately.

## Step 3: Validate Changes

### 3.1 Run validation script
```bash
./flux/scripts/validate.sh
```

### 3.2 Check for breaking changes
Review the Flux release notes for the target version. Common areas to check:
- API version changes
- Breaking changes in controllers
- Deprecated features

## Step 4: Test in Staging (Optional)

### 4.1 Update staging cluster
```bash
# Export for staging
flux install \
  --version=v2.x.x \
  --export > ./flux/clusters/staging/flux-system/gotk-components.yaml

# Commit and test staging
git add ./flux/clusters/staging/flux-system/gotk-components.yaml
git commit -m "chore: update Flux to v2.x.x in staging"
git push origin main
```

### 4.2 Monitor staging deployment
```bash
# Watch staging reconciliation
flux get kustomizations -n flux-system --context staging

# Check pod status
kubectl get pods -n flux-system --context staging --watch
```

## Step 5: Deploy to Production

### 5.1 Commit production changes
```bash
git add ./flux/clusters/production/flux-system/gotk-components.yaml
git commit -m "chore: update Flux to v2.x.x"
git push origin main
```

### 5.2 Monitor upgrade process
```bash
# Watch Flux pods restarting
kubectl get pods -n flux-system --watch

# Check Flux controller logs
kubectl logs -n flux-system deployment/source-controller -f
kubectl logs -n flux-system deployment/kustomize-controller -f
kubectl logs -n flux-system deployment/helm-controller -f
```

### 5.3 Verify upgrade completion
```bash
# Check new version
kubectl get pods -n flux-system -l app.kubernetes.io/part-of=flux -o jsonpath='{.items[*].spec.containers[*].image}'

# Verify controllers are healthy
flux check

# Test reconciliation
flux reconcile kustomization flux-system --with-source
```

## Step 6: Post-Upgrade Verification

### 6.1 Check all kustomizations
```bash
flux get kustomizations --all-namespaces

# Look for any errors
flux get kustomizations --all-namespaces | grep -v "True"
```

### 6.2 Check Helm releases
```bash
flux get helmreleases --all-namespaces

# Verify reconciliation
flux reconcile helmrelease <name> -n <namespace>
```

### 6.3 Check source repositories
```bash
flux get sources git --all-namespaces
flux get sources helm --all-namespaces
flux get sources oci --all-namespaces
```

## Troubleshooting

### Issue 1: Flux pods not starting
```bash
# Check pod events
kubectl describe pod -n flux-system <pod-name>

# Check for image pull errors
kubectl logs -n flux-system <pod-name> --previous

# Check resource constraints
kubectl top pods -n flux-system
```

### Issue 2: Reconciliation failures
```bash
# Check controller logs
kubectl logs -n flux-system deployment/kustomize-controller | tail -100

# Check specific kustomization
flux describe kustomization <name> -n <namespace>

# Force reconciliation
flux reconcile kustomization <name> -n <namespace> --with-source
```

### Issue 3: API version mismatches
If Flux uses newer API versions not supported by existing resources:

1. Check error messages in logs
2. Update resource manifests to newer API versions if needed
3. Refer to Flux upgrade documentation for migration paths

### Issue 4: Performance degradation
If reconciliation becomes slower after upgrade:

1. Check controller resource usage
2. Verify performance patches are still applied
3. Adjust concurrency settings if needed

## Rollback Procedure

### Immediate rollback (if upgrade fails)
```bash
# Revert to previous commit
git revert HEAD

# Force reconciliation
flux reconcile kustomization flux-system --with-source

# Alternatively, manually apply previous version
flux install \
  --version=v2.previous.version \
  --export | kubectl apply -f -
```

### Manual rollback (if Git revert not possible)
```bash
# Restore previous gotk-components.yaml
cp ./flux/clusters/production/flux-system/gotk-components.yaml.bak ./flux/clusters/production/flux-system/gotk-components.yaml

# Apply manually
kubectl apply -f ./flux/clusters/production/flux-system/gotk-components.yaml
```

## Best Practices

### 1. Always test in staging first
- Use staging cluster to validate upgrades
- Monitor for 24 hours before production deployment

### 2. Maintain backups
```bash
# Backup current manifests before upgrade
cp ./flux/clusters/production/flux-system/gotk-components.yaml \
   ./flux/clusters/production/flux-system/gotk-components.yaml.bak
```

### 3. Monitor during upgrade
- Watch pod restart sequence
- Monitor reconciliation status
- Check for error logs

### 4. Update documentation
- Update version in AGENTS.md files
- Document any breaking changes
- Update troubleshooting guides

## Version History

| Version | Date | Notes |
|---------|------|-------|
| v2.7.5 | Current | Production version |
| v2.x.x | Target | Planned upgrade |

## Reference

- Flux Documentation: https://fluxcd.io/flux/installation/
- Upgrade Guide: https://fluxcd.io/flux/installation/upgrade/
- Release Notes: https://github.com/fluxcd/flux2/releases
- Agent Rules: `core/standards/rules.md`
- Flux AGENTS.md: `flux/AGENTS.md`