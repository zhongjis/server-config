# Troubleshoot Flux CD Workflow

This workflow guides you through diagnosing and resolving common FluxCD issues in the Kubernetes cluster.

## Quick Diagnostics

### 1. Check Flux System Status
```bash
# Basic Flux health check
flux check

# Check all kustomizations
flux get kustomizations --all-namespaces

# Check all Helm releases
flux get helmreleases --all-namespaces

# Check source repositories
flux get sources git --all-namespaces
flux get sources helm --all-namespaces
flux get sources oci --all-namespaces
```

### 2. Check Pod Status
```bash
# Flux system pods
kubectl get pods -n flux-system

# All pods with issues
kubectl get pods --all-namespaces | grep -v "Running\|Completed"

# Pods with restarts
kubectl get pods --all-namespaces --field-selector=status.phase!=Running
```

## Common Issues & Solutions

### Issue 1: Kustomization Not Reconciling

**Symptoms:**
- `flux get kustomizations` shows `False` or unknown status
- Last reconciliation time is old
- Resources not applied to cluster

**Diagnosis:**
```bash
# Check specific kustomization
flux describe kustomization <name> -n <namespace>

# Check kustomization status in detail
kubectl get kustomization <name> -n <namespace> -o yaml

# Check controller logs
kubectl logs -n flux-system deployment/kustomize-controller | tail -100

# Check events
kubectl get events -n flux-system --sort-by='.lastTimestamp'
```

**Common Causes & Fixes:**

1. **Source not available:**
   ```bash
   # Check source
   flux describe source git <name> -n <namespace>
   flux describe source helm <name> -n <namespace>
   
   # Suspend and resume to force refresh
   flux suspend kustomization <name> -n <namespace>
   flux resume kustomization <name> -n <namespace>
   ```

2. **Validation error in manifests:**
   ```bash
   # Run validation script
   ./flux/scripts/validate.sh
   
   # Force reconciliation
   flux reconcile kustomization <name> -n <namespace> --with-source
   ```

3. **Dependency not ready:**
   ```bash
   # Check dependencies
   kubectl get kustomization <name> -n <namespace> -o jsonpath='{.spec.dependsOn}'
   
   # Check dependent kustomizations
   flux get kustomizations | grep -A5 "dependsOn"
   ```

### Issue 2: HelmRelease Not Deploying

**Symptoms:**
- `flux get helmreleases` shows failure
- Helm chart not deployed
- Resources missing in cluster

**Diagnosis:**
```bash
# Check Helm release details
flux describe helmrelease <name> -n <namespace>

# Get detailed status
kubectl get helmrelease <name> -n <namespace> -o yaml

# Check helm controller logs
kubectl logs -n flux-system deployment/helm-controller | grep -A5 -B5 "<name>"

# Check release history
flux get helmrelease <name> -n <namespace> -o yaml | grep -A10 "status"
```

**Common Causes & Fixes:**

1. **Chart not found:**
   ```bash
   # Check Helm repository
   flux describe source helm <repo-name> -n <namespace>
   
   # Test chart access
   kubectl get helmrepository <repo-name> -n <namespace> -o yaml
   ```

2. **Values validation error:**
   ```bash
   # Check values syntax
   kubectl get helmrelease <name> -n <namespace> -o jsonpath='{.spec.values}' | yq e -P -
   
   # Check valuesFrom secrets
   kubectl get secret <secret-name> -n <namespace> -o yaml | sops -d /dev/stdin | yq e -P -
   ```

3. **Upgrade failed:**
   ```bash
   # Check last failed release
   flux get helmrelease <name> -n <namespace> -o jsonpath='{.status.lastAttemptedRevision}'
   
   # Rollback to previous version
   flux suspend helmrelease <name> -n <namespace>
   # Edit HelmRelease.yaml to previous version
   flux resume helmrelease <name> -n <namespace>
   ```

### Issue 3: Source Repository Issues

**Symptoms:**
- Source status shows `False`
- Charts or git content not updating
- Authentication errors

**Diagnosis:**
```bash
# Check source status
flux describe source <type> <name> -n <namespace>

# Check source controller logs
kubectl logs -n flux-system deployment/source-controller | grep -A5 -B5 "<name>"

# Check authentication
kubectl get secret -n <namespace> | grep flux
```

**Common Causes & Fixes:**

1. **Git repository authentication:**
   ```bash
   # Check git repository secret
   kubectl get secret <git-secret> -n <namespace> -o yaml
   
   # Update git credentials
   # Edit secret in flux/secrets/production/
   # Re-encrypt with SOPS
   sops --age=age1gff6wle45ktarxc89vfqnq6qawwjcxd5jed4jnuhhddpeqxz6d7q8wq8gn \
     --encrypt --encrypted-regex '^(data|stringData)$' --in-place <file>.yaml
   ```

2. **Helm repository unavailable:**
   ```bash
   # Test repository URL
   curl -I <repository-url>/index.yaml
   
   # Check network policies
   kubectl get networkpolicies -n flux-system
   ```

3. **OCI registry authentication:**
   ```bash
   # Check OCI repository configuration
   kubectl get ocirepository <name> -n <namespace> -o yaml
   
   # Verify registry access
   flux pull artifact oci://<registry-url>/<chart>
   ```

### Issue 4: Secret Injection Problems

**Symptoms:**
- Application missing configuration
- Authentication failures in pods
- `valuesFrom` not working

**Diagnosis:**
```bash
# Check if secret exists
kubectl get secret <secret-name> -n <namespace>

# Check secret contents (decrypt if needed)
sops -d ./flux/secrets/production/<secret-file>.yaml | yq e -P -

# Check HelmRelease valuesFrom
kubectl get helmrelease <app> -n <namespace> -o jsonpath='{.spec.valuesFrom}' | yq e -P -
```

**Common Causes & Fixes:**

1. **Secret not created:**
   ```bash
   # Create missing secret
   # Follow deploy-new-app workflow
   # Encrypt with SOPS
   ```

2. **Wrong secret name or namespace:**
   ```bash
   # Verify secret reference matches actual secret
   kubectl get secret --all-namespaces | grep <secret-name>
   
   # Update HelmRelease.yaml with correct reference
   ```

3. **SOPS decryption failure:**
   ```bash
   # Check age key availability
   kubectl get secret sops-age -n flux-system
   
   # Test decryption
   sops -d ./flux/secrets/production/<file>.yaml > /dev/null && echo "Decryption OK"
   ```

### Issue 5: Performance Issues

**Symptoms:**
- Slow reconciliation
- Controllers using high CPU/memory
- Reconciliation backlog

**Diagnosis:**
```bash
# Check controller resource usage
kubectl top pods -n flux-system

# Check reconciliation intervals
flux get kustomizations --all-namespaces -o wide

# Check controller logs for errors
kubectl logs -n flux-system deployment/kustomize-controller --tail=100 | grep -i "error\|warning\|slow"
```

**Common Causes & Fixes:**

1. **Too many resources:**
   ```bash
   # Check total number of managed resources
   kubectl get all --all-namespaces | wc -l
   
   # Consider increasing controller resources
   # Edit gotk-components.yaml resource limits
   ```

2. **Network issues:**
   ```bash
   # Check network connectivity
   kubectl run -n flux-system test-net --image=alpine --rm -it -- ping <repository-host>
   
   # Check DNS resolution
   kubectl run -n flux-system test-dns --image=alpine --rm -it -- nslookup <repository-host>
   ```

3. **Concurrency limits:**
   ```bash
   # Current concurrency settings (patched to --concurrent=20)
   kubectl get deployment -n flux-system kustomize-controller -o jsonpath='{.spec.template.spec.containers[0].args}'
   
   # Adjust if needed in gotk-components.yaml
   ```

## Advanced Troubleshooting

### Log Analysis
```bash
# Follow controller logs in real-time
kubectl logs -n flux-system deployment/kustomize-controller -f

# Check for specific error patterns
kubectl logs -n flux-system deployment/source-controller --tail=500 | grep -E "(error|Error|ERROR|failed|Failed)"

# Get logs from all flux pods
for pod in $(kubectl get pods -n flux-system -o name); do
  echo "=== $pod ==="
  kubectl logs -n flux-system $pod --tail=50
done
```

### Event Analysis
```bash
# Get all events sorted by time
kubectl get events --all-namespaces --sort-by='.lastTimestamp'

# Filter for warning and error events
kubectl get events --all-namespaces --field-selector=type!=Normal

# Check events for specific resource
kubectl describe kustomization <name> -n <namespace>
kubectl describe helmrelease <name> -n <namespace>
```

### Resource Inspection
```bash
# Get complete resource tree
flux tree kustomization flux-system

# Export current state
flux export all --all-namespaces > flux-state.yaml

# Compare with git state
kustomize build ./flux/apps/production > current-state.yaml
diff -u expected-state.yaml current-state.yaml
```

## Recovery Procedures

### Complete Flux Reset
```bash
# Backup current state
flux export all --all-namespaces > flux-backup-$(date +%Y%m%d).yaml

# Uninstall Flux
flux uninstall --namespace=flux-system --silent

# Reinstall from git
flux bootstrap git \
  --url=<git-repo-url> \
  --branch=main \
  --path=./flux/clusters/production \
  --namespace=flux-system
```

### Manual Resource Recovery
```bash
# If Flux is completely broken, apply manifests manually
kustomize build ./flux/apps/production | kubectl apply -f -

# Or apply specific components
kustomize build ./flux/infrastructure/controllers | kubectl apply -f -
kustomize build ./flux/apps/base/<app> | kubectl apply -f -
```

## Prevention & Monitoring

### Regular Health Checks
```bash
# Daily check script
#!/bin/bash
flux check
flux get kustomizations --all-namespaces | grep -v "True"
flux get helmreleases --all-namespaces | grep -v "True"
kubectl get pods -n flux-system | grep -v "Running"
```

### Alert Configuration
Monitor for:
- Kustomization/HelmRelease not ready > 1 hour
- Source repository failures
- Controller pod restarts
- High resource usage

### Backup Strategy
```bash
# Regular backups
flux export all --all-namespaces > backup/flux-state-$(date +%Y%m%d).yaml

# Backup encrypted secrets
cp -r ./flux/secrets/production backup/secrets-$(date +%Y%m%d)
```

## Reference Commands Cheat Sheet

```bash
# Force reconciliation
flux reconcile kustomization <name> -n <namespace> --with-source
flux reconcile helmrelease <name> -n <namespace>

# Suspend/resume
flux suspend kustomization <name> -n <namespace>
flux resume kustomization <name> -n <namespace>

# Export/backup
flux export all --all-namespaces > backup.yaml
flux export source git --all-namespaces > sources.yaml

# Validation
./flux/scripts/validate.sh
kustomize build ./flux/apps/production > /dev/null

# Logs
kubectl logs -n flux-system -l app=kustomize-controller --tail=100
kubectl logs -n flux-system -l app=helm-controller --tail=100
```

## Related Documentation

- Flux Documentation: https://fluxcd.io/flux/
- Troubleshooting Guide: https://fluxcd.io/flux/guides/troubleshooting/
- Agent Rules: `core/standards/rules.md`
- Flux AGENTS.md: `flux/AGENTS.md`
- Update Flux Workflow: `core/workflows/update-flux.md`