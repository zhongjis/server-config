# Agent MCP Runbook

Use MCP servers from the repo root with the checked-in `mcp.json`. The Flux MCP entry runs locally over stdio, read-only, and with secret masking enabled.

## Safety rules
- Secret values must remain masked in all MCP output.
- Do not commit credentials, kubeconfig files, tokens, decrypted SOPS data, or plaintext secrets.
- Do not add `KUBECONFIG` or credential environment variables to `mcp.json`.
- The normal path for cluster changes is GitOps repo changes followed by Flux reconciliation.
- Direct live mutation, reconcile, suspend, resume, delete, restart, or apply is break-glass or requires explicit user approval.
- Do not expose MCP over the network with `http` or `sse` transports by default.

## Read-only Flux workflows

```bash
# Package/help check
nix run nixpkgs#fluxcd-operator-mcp -- --help
```

- Inspect FluxInstance: use the Flux MCP server to read `FluxInstance/flux` in `flux-system`, then check status conditions and the configured distribution version.
- List failing Kustomizations: ask Flux MCP for Kustomizations across namespaces and filter objects whose Ready condition is not `True`.
- List failing HelmReleases: ask Flux MCP for HelmReleases across namespaces and filter objects whose Ready condition is not `True`.
- Read logs: ask Flux MCP for Flux controller logs, preferring error-level logs first when debugging reconciliation failures.

## Reconcile after Git merge

Only reconcile after a Git merge when the user explicitly requests it. Keep the checked-in MCP default read-only; use an explicitly approved break-glass command such as:

```bash
# Reconcile source and kustomization after the merge is pushed
flux reconcile source git flux-system -n flux-system
flux reconcile kustomization <name> -n flux-system --with-source
```
