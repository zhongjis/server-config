# Helm Application Template

This template provides a standard structure for new Helm-based applications in the FluxCD GitOps repository.

## Template Structure

```
my-app/
├── Namespace.yaml          # Application namespace
├── HelmRepo.yaml          # Helm repository source
├── HelmRelease.yaml       # Main deployment
├── kustomization.yaml     # Resource list
├── Cluster.yaml           # Optional: PostgreSQL cluster
└── GrafanaDashboard.yaml  # Optional: Monitoring dashboard
```

## Files

### 1. Namespace.yaml
```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: my-app
  labels:
    toolkit.fluxcd.io/tenant: sre-team
```

### 2. HelmRepo.yaml
```yaml
apiVersion: source.toolkit.fluxcd.io/v1
kind: HelmRepository
metadata:
  name: my-app
  namespace: my-app
spec:
  interval: 24h
  url: https://charts.example.com  # Replace with actual repository
```

### 3. HelmRelease.yaml
```yaml
apiVersion: helm.toolkit.fluxcd.io/v2
kind: HelmRelease
metadata:
  name: my-app
  namespace: my-app
spec:
  interval: 30m
  chart:
    spec:
      chart: my-app-chart  # Chart name in repository
      version: "1.0.0"     # Exact version (not semver range)
      sourceRef:
        kind: HelmRepository
        name: my-app
        namespace: my-app
  
  # Values configuration
  values:
    image:
      repository: myapp
      tag: "v1.0.0"
      pullPolicy: IfNotPresent
    
    ingress:
      enabled: true
      className: nginx
      annotations:
        cert-manager.io/cluster-issuer: "cloudflare-issuer"
        kubernetes.io/tls-acme: "true"
        gethomepage.dev/enabled: "true"
        gethomepage.dev/name: "My Application"
        gethomepage.dev/description: "Application description"
      hosts:
        - host: my-app.example.com
          paths:
            - path: /
              pathType: Prefix
      tls:
        - secretName: my-app-tls
          hosts:
            - my-app.example.com
    
    persistence:
      enabled: true
      storageClass: longhorn
      size: 10Gi
      accessMode: ReadWriteOnce
    
    resources:
      requests:
        memory: "256Mi"
        cpu: "250m"
      limits:
        memory: "512Mi"
        cpu: "500m"
    
    # Application-specific configuration
    config:
      environment: production
      debug: false
  
  # Optional dependencies
  # dependsOn:
  #   - name: postgresql
  #     namespace: postgresql
  
  # Optional secret injection
  # valuesFrom:
  #   - kind: Secret
  #     name: my-app-secrets
  #     valuesKey: values.yaml
  #     targetPath: .
```

### 4. kustomization.yaml
```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  - Namespace.yaml
  - HelmRepo.yaml
  - HelmRelease.yaml
  # Optional:
  # - Cluster.yaml
  # - GrafanaDashboard.yaml
```

### 5. Cluster.yaml (Optional - for PostgreSQL)
```yaml
apiVersion: postgresql.cnpg.io/v1
kind: Cluster
metadata:
  name: my-app
  namespace: my-app
spec:
  instances: 1
  storage:
    size: 10Gi
    storageClass: longhorn
  bootstrap:
    initdb:
      database: myapp
      owner: myapp
```

### 6. GrafanaDashboard.yaml (Optional)
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: my-app-dashboard
  namespace: monitoring
  labels:
    grafana_dashboard: "1"
data:
  my-app.json: |
    {
      "title": "My Application Dashboard",
      "panels": [],
      "tags": ["my-app"]
    }
```

## Secret File Template

Create `my-app-secrets-flux.yaml` in `flux/secrets/production/`:

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: my-app-secrets
  namespace: my-app
type: Opaque
data:
  # Base64 encoded values
  password: $(echo -n "secretpassword" | base64)
  api-key: $(echo -n "apikey123" | base64)
```

**Important**: Encrypt with SOPS before committing:
```bash
sops --age=age1gff6wle45ktarxc89vfqnq6qawwjcxd5jed4jnuhhddpeqxz6d7q8wq8gn \
  --encrypt --encrypted-regex '^(data|stringData)$' --in-place my-app-secrets-flux.yaml
```

## Usage

1. **Copy template**:
   ```bash
   cp -r .opencode/context/core/templates/helm-app-template/* flux/apps/base/my-app/
   ```

2. **Customize files**:
   - Update `my-app` to actual application name
   - Set correct Helm repository URL
   - Configure values for your application
   - Add dependencies if needed

3. **Create secrets** (if needed):
   - Follow secret naming pattern: `<app>-secrets-flux.yaml`
   - Encrypt with SOPS
   - Reference in HelmRelease.yaml

4. **Add to production**:
   - Edit `flux/apps/production/kustomization.yaml`
   - Add `- ../base/my-app` to resources

5. **Validate**:
   ```bash
   ./flux/scripts/validate.sh
   ```

## Reference

- Deploy New App Workflow: `core/workflows/deploy-new-app.md`
- Agent Rules: `core/standards/rules.md`
- Code Standards: `core/standards/code.md`