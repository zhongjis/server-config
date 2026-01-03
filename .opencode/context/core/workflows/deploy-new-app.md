# Deploy New Application Workflow

This workflow guides you through deploying a new application to the Kubernetes cluster using FluxCD GitOps.

## Prerequisites

1. **Application details**:
   - Application name (lowercase, kebab-case)
   - Helm chart repository URL or OCI registry
   - Chart name and version
   - Configuration values

2. **Secrets** (if needed):
   - API keys, passwords, tokens
   - Database credentials
   - External service credentials

## Step 1: Create Application Directory Structure

### 1.1 Choose application name
```bash
# App name should be lowercase with hyphens (kebab-case)
APP_NAME="my-new-app"
```

### 1.2 Create directory
```bash
mkdir -p ./flux/apps/base/${APP_NAME}
cd ./flux/apps/base/${APP_NAME}
```

## Step 2: Create Base Manifests

### 2.1 Create Namespace.yaml
```yaml
# ./flux/apps/base/${APP_NAME}/Namespace.yaml
apiVersion: v1
kind: Namespace
metadata:
  name: ${APP_NAME}
  labels:
    toolkit.fluxcd.io/tenant: sre-team
```

### 2.2 Create Helm Repository or OCI Repository

**Option A: Helm Repository (external charts)**
```yaml
# ./flux/apps/base/${APP_NAME}/HelmRepo.yaml
apiVersion: source.toolkit.fluxcd.io/v1
kind: HelmRepository
metadata:
  name: ${APP_NAME}
  namespace: ${APP_NAME}
spec:
  interval: 24h
  url: https://charts.example.com  # Replace with actual repository URL
```

**Option B: OCI Repository (OCI-based charts)**
```yaml
# ./flux/apps/base/${APP_NAME}/OCIRepository.yaml  
apiVersion: source.toolkit.fluxcd.io/v1
kind: OCIRepository
metadata:
  name: ${APP_NAME}
  namespace: ${APP_NAME}
spec:
  interval: 24h
  url: oci://registry.example.com/charts  # Replace with actual OCI URL
  ref:
    tag: "1.0.0"  # Specify chart version
```

### 2.3 Create HelmRelease.yaml
```yaml
# ./flux/apps/base/${APP_NAME}/HelmRelease.yaml
apiVersion: helm.toolkit.fluxcd.io/v2
kind: HelmRelease
metadata:
  name: ${APP_NAME}
  namespace: ${APP_NAME}
spec:
  interval: 30m
  chart:
    spec:
      chart: ${CHART_NAME}  # Chart name within repository
      version: "1.0.0"      # Exact chart version (not semver range)
      sourceRef:
        kind: HelmRepository  # or OCIRepository
        name: ${APP_NAME}
        namespace: ${APP_NAME}
  values:
    # Application-specific values
    image:
      repository: myapp
      tag: "v1.0.0"
    
    ingress:
      enabled: true
      className: nginx
      hosts:
        - host: ${APP_NAME}.example.com
          paths:
            - path: /
              pathType: Prefix
      tls:
        - secretName: ${APP_NAME}-tls
          hosts:
            - ${APP_NAME}.example.com
    
    persistence:
      enabled: true
      storageClass: longhorn
      size: 10Gi
    
    resources:
      requests:
        memory: "256Mi"
        cpu: "250m"
      limits:
        memory: "512Mi"
        cpu: "500m"
    
  # Optional: Dependencies on other applications or infrastructure
  # dependsOn:
  #   - name: cert-manager
  #     namespace: cert-manager
```

### 2.4 Create kustomization.yaml
```yaml
# ./flux/apps/base/${APP_NAME}/kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  - Namespace.yaml
  - HelmRepo.yaml  # or OCIRepository.yaml
  - HelmRelease.yaml
```

## Step 3: Add Optional Components (if needed)

### 3.1 Database (CloudNativePG)
If the app needs PostgreSQL:
```yaml
# ./flux/apps/base/${APP_NAME}/Cluster.yaml
apiVersion: postgresql.cnpg.io/v1
kind: Cluster
metadata:
  name: ${APP_NAME}
  namespace: ${APP_NAME}
spec:
  instances: 1
  storage:
    size: 10Gi
    storageClass: longhorn
```

Update HelmRelease.yaml to add dependency:
```yaml
# In HelmRelease.yaml spec
dependsOn:
  - name: ${APP_NAME}-cnpg-cluster
    namespace: ${APP_NAME}
```

Update kustomization.yaml:
```yaml
resources:
  - Namespace.yaml
  - HelmRepo.yaml
  - Cluster.yaml
  - HelmRelease.yaml
```

### 3.2 Monitoring (Grafana Dashboard)
```yaml
# ./flux/apps/base/${APP_NAME}/GrafanaDashboard.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: ${APP_NAME}-dashboard
  namespace: monitoring
  labels:
    grafana_dashboard: "1"
data:
  ${APP_NAME}.json: |
    {
      "title": "${APP_NAME} Dashboard",
      "panels": [...]
    }
```

## Step 4: Create Secrets (if needed)

### 4.1 Create secret file template
```bash
# Create secret template (unencrypted)
cat > /tmp/${APP_NAME}-secrets.yaml << EOF
apiVersion: v1
kind: Secret
metadata:
  name: ${APP_NAME}-secrets
  namespace: ${APP_NAME}
type: Opaque
data:
  # Base64 encoded values
  password: $(echo -n "secretpassword" | base64)
  api-key: $(echo -n "apikey123" | base64)
EOF
```

### 4.2 Encrypt with SOPS
```bash
# Move to secrets directory
mv /tmp/${APP_NAME}-secrets.yaml ./flux/secrets/production/

# Encrypt with SOPS
cd ./flux/secrets/production
sops --age=age1gff6wle45ktarxc89vfqnq6qawwjcxd5jed4jnuhhddpeqxz6d7q8wq8gn \
  --encrypt --encrypted-regex '^(data|stringData)$' --in-place ${APP_NAME}-secrets-flux.yaml
```

**Note**: Use naming pattern `<app>-secrets-flux.yaml` for new applications.

### 4.3 Reference secrets in HelmRelease
```yaml
# In HelmRelease.yaml spec
valuesFrom:
  - kind: Secret
    name: ${APP_NAME}-secrets
    valuesKey: values.yaml  # or specific key
    targetPath: .           # Inject at root of values
```

## Step 5: Add to Production Overlay

### 5.1 Edit production kustomization
```bash
cd ./flux/apps/production
```

Edit `kustomization.yaml` to add the new app:
```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  # ... existing resources ...
  - ../base/${APP_NAME}
```

## Step 6: Validate Changes

### 6.1 Run validation script
```bash
cd /home/zshen/personal/server-config
./flux/scripts/validate.sh
```

### 6.2 Preview kustomize build
```bash
kustomize build ./flux/apps/production | grep -A5 -B5 "${APP_NAME}"
```

### 6.3 Test secret decryption
```bash
sops -d ./flux/secrets/production/${APP_NAME}-secrets-flux.yaml | head -20
```

## Step 7: Commit and Deploy

### 7.1 Commit changes
```bash
git add .
git commit -m "feat: add ${APP_NAME} application"
```

### 7.2 Push to repository
```bash
git push origin main
```

### 7.3 Monitor Flux reconciliation
```bash
# Watch for the new application
flux get kustomizations --watch

# Check Helm releases
flux get helmreleases --all-namespaces | grep ${APP_NAME}

# Check pod status
kubectl get pods -n ${APP_NAME} --watch
```

## Troubleshooting

### Common Issues

1. **Validation errors**:
   ```bash
   ./flux/scripts/validate.sh
   # Fix any reported errors before committing
   ```

2. **Flux not reconciling**:
   ```bash
   flux reconcile kustomization flux-system --with-source
   flux reconcile helmrelease ${APP_NAME} -n ${APP_NAME}
   ```

3. **Secret injection issues**:
   ```bash
   # Check if secret exists
   kubectl get secret ${APP_NAME}-secrets -n ${APP_NAME}
   
   # Check HelmRelease values
   flux get helmrelease ${APP_NAME} -n ${APP_NAME} -o yaml | grep -A10 "valuesFrom"
   ```

## Template Repository

For a complete template, see:
- `core/templates/helm-app-template/` - Complete Helm app template
- `core/templates/oci-app-template/` - OCI-based app template

## Reference

- Agent Rules: `core/standards/rules.md`
- Code Standards: `core/standards/code.md`
- Flux AGENTS.md: `flux/AGENTS.md`