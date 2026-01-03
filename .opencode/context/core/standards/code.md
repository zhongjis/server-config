# Code Standards

## YAML Formatting

### Indentation
- **2 spaces** per indentation level (never tabs)
- Consistent indentation throughout files

### Line Length
- Maximum 120 characters per line
- Break long strings or arrays for readability

### File Structure
- Use `---` separators between YAML documents in multi-document files
- Include comments for complex or non-obvious configurations

## Kubernetes Resources

### Naming Conventions
- **Resource names**: lowercase with hyphens (kebab-case)
  - Good: `cert-manager`, `ingress-nginx`, `external-dns`
  - Bad: `CertManager`, `ingress_nginx`, `externalDns`

- **Labels**: Use `app.kubernetes.io/` standard labels
  ```yaml
  labels:
    app.kubernetes.io/name: cert-manager
    app.kubernetes.io/instance: cert-manager
    app.kubernetes.io/version: "1.19.2"
    app.kubernetes.io/component: controller
    app.kubernetes.io/part-of: infrastructure
  ```

### Resource Definitions
- **API Version**: Always specify full API version
- **Kind**: Use proper capitalization (e.g., `Deployment`, `Service`, `ConfigMap`)
- **Metadata**: Include namespace when applicable

## FluxCD Specific Standards

### Kustomization Structure
```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  - Namespace.yaml
  - HelmRepo.yaml  # or OCIRepository.yaml
  - HelmRelease.yaml
  # Optional:
  # - Cluster.yaml
  # - GrafanaDashboard.yaml
```

### HelmRelease Configuration
- **Version pinning**: Use exact chart versions (e.g., `version: 1.19.2`)
- **Interval**: Standard intervals:
  - Source repositories: `24h`
  - Helm releases: `30m`
  - Kustomizations: `10m`

- **Values structure**: Organize values logically:
  ```yaml
  values:
    image:
      repository: nginx
      tag: "1.25.3"
      pullPolicy: IfNotPresent
    
    ingress:
      enabled: true
      className: nginx
      hosts:
        - host: app.example.com
          paths:
            - path: /
              pathType: Prefix
  ```

## NixOS Standards

### Module Structure
- **Default exports**: Modules should export configuration options
- **Function arguments**: Use `{ config, lib, pkgs, ... }` pattern
- **Option declarations**: Use `lib.mkOption` with proper types and descriptions

### Flake Structure
- **Inputs**: Specify `follows` for consistent dependency versions
- **Outputs**: Use helper functions from `lib/defaults.nix`
- **System configurations**: Reference shared modules appropriately

### Disko Configuration
- **Partition scheme**: Follow `disko-config.nix` patterns
- **File systems**: Use appropriate mount options for NVMe drives

## File Naming

### Kubernetes Resources
- **PascalCase** for Kubernetes resource files:
  - `Namespace.yaml`
  - `Deployment.yaml` 
  - `Service.yaml`
  - `ConfigMap.yaml`
  - `Secret.yaml`

### Application Directories
- **lowercase-kebab** for application names:
  - `flux/apps/base/cert-manager/`
  - `flux/apps/base/ingress-nginx/`
  - `flux/apps/base/external-dns/`

### Secret Files
- Follow naming patterns from `rules.md`:
  - New: `<app>-secrets-flux.yaml`
  - Legacy: `<app>-secrets-fluxcd.yaml`
  - Legacy: `<app>-secrets.yaml`

## Comment Standards

### YAML Comments
```yaml
# Main application deployment
apiVersion: apps/v1
kind: Deployment
metadata:
  name: myapp
spec:
  replicas: 2
  selector:
    matchLabels:
      app: myapp
  template:
    metadata:
      labels:
        app: myapp
    spec:
      containers:
      - name: main
        image: nginx:1.25.3
        # Health check configuration
        livenessProbe:
          httpGet:
            path: /healthz
            port: 8080
```

### Nix Comments
```nix
# Enable k3s service with custom configuration
services.k3s = {
  enable = true;
  # Disable built-in load balancer (using metallb instead)
  disableLoadBalancer = true;
  # Disable built-in ingress (using ingress-nginx instead)
  disableTraefik = true;
  # Enable metrics for monitoring
  enableMetrics = true;
};
```

## Validation

### Pre-commit Validation
Always run validation before committing:
```bash
./flux/scripts/validate.sh
```

### Manual Validation
```bash
# Validate specific files
kubeconform -strict -ignore-missing-schemas file.yaml

# Build kustomize overlays for preview
kustomize build ./flux/apps/production
```

## Common Patterns

### Ingress Configuration
```yaml
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
    - host: app.example.com
      paths:
        - path: /
          pathType: Prefix
  tls:
    - secretName: app-tls
      hosts:
        - app.example.com
```

### Resource Limits
```yaml
resources:
  requests:
    memory: "256Mi"
    cpu: "250m"
  limits:
    memory: "512Mi"
    cpu: "500m"
```

### Persistence (Longhorn)
```yaml
persistence:
  enabled: true
  storageClass: "longhorn"
  size: "10Gi"
  accessMode: ReadWriteOnce
```