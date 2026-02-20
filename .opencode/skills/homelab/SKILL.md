---
name: homelab
description: |
  Manage homelab k3s nodes (homelab-0, homelab-1, homelab-2) for this repository.
  Use when user wants to:
  (1) Power cycle nodes (power down, restart, reboot)
  (2) Apply NixOS configuration to k3s nodes via Colmena
  (3) Upgrade nodes (drain, apply, uncordon)
  (4) Check node status
  (5) Handle CNPG PostgreSQL cluster maintenance
  Triggers: "restart homelab", "reboot nodes", "apply nixos", "upgrade homelab", 
  "power down", "colmena apply", "drain node", "uncordon", "node maintenance",
  "postgres maintenance", "cnpg"
---

# Homelab Node Management

Manage 3 k3s nodes running NixOS, deployed via Colmena.

## Nodes

| Node | Role | IP | Hardware |
|------|------|-----|----------|
| homelab-0 | master | 192.168.50.104 | ThinkCentre i7 |
| homelab-1 | worker | 192.168.50.103 | ThinkCentre i5 |
| homelab-2 | worker | 192.168.50.105 | ThinkCentre |

## Quick Commands

### Check Status

```bash
# Kubernetes nodes
kubectl get nodes -o wide

# CNPG cluster status (run for each app)
kubectl cnpg status <cluster-name> -n <namespace>
```

### Apply NixOS Configuration

```bash
# All nodes
colmena apply

# Single node
colmena apply --on homelab-0

# Apply and reboot
colmena apply --on homelab-0 --reboot

# Build only (no deploy)
colmena build
```

## Node Upgrade Procedure

**Order: workers first, master last** → homelab-1 → homelab-2 → homelab-0

For each node:

### Step 1: Pre-flight CNPG Check

```bash
# Check all CNPG clusters are healthy before starting
kubectl cnpg status authentik-pg -n authentik
kubectl cnpg status n8n-pg -n n8n
kubectl cnpg status dify-pg -n dify
kubectl cnpg status litellm-pg -n litellm
kubectl cnpg status mlflow-pg -n mlflow
kubectl cnpg status freshrss-pg -n freshrss
kubectl cnpg status langfuse-pg -n langfuse
```

All clusters should show 3 healthy instances with no replication lag.

### Step 2: Drain Node

```bash
kubectl drain <node> --ignore-daemonsets --disable-eviction --delete-emptydir-data --force
```

CNPG PodDisruptionBudgets automatically:
- Trigger switchover if primary is on this node
- Ensure cluster quorum is maintained

### Step 3: Apply and Reboot

```bash
colmena apply --on <node> --reboot
```

### Step 4: Uncordon and Verify

```bash
# Wait for node to come back online
kubectl get nodes -w

# Uncordon
kubectl uncordon <node>

# Verify CNPG clusters recovered
kubectl cnpg status authentik-pg -n authentik
# ... repeat for other clusters
```

Wait for all CNPG clusters to show 3 healthy instances before proceeding to next node.

## Power Operations

### Graceful Reboot (Single Node)

Use full upgrade procedure above for graceful restart.

### Power Off (Manual Power-on Required)

```bash
ssh root@192.168.50.104 poweroff  # homelab-0
ssh root@192.168.50.103 poweroff  # homelab-1
ssh root@192.168.50.105 poweroff  # homelab-2
```

## CNPG Clusters Reference

| App | Cluster Name | Namespace | PostgreSQL |
|-----|--------------|-----------|------------|
| authentik | authentik-pg | authentik | 17 |
| n8n | n8n-pg | n8n | 17 |
| dify | dify-pg | dify | 17 |
| litellm | litellm-pg | litellm | 18 |
| mlflow | mlflow-pg | mlflow | 18 |
| freshrss | freshrss-pg | freshrss | 18 |
| langfuse | langfuse-pg | langfuse | 18 |

All clusters: 3 instances, 5Gi Longhorn storage, monitoring enabled.

## CNPG Troubleshooting

```bash
# Manual switchover (if needed before maintenance)
kubectl cnpg promote <cluster-name> <replica-pod-name> -n <namespace>

# Check operator logs
kubectl logs -n cnpg-system -l app.kubernetes.io/name=cloudnative-pg

# Rolling restart of cluster
kubectl cnpg restart <cluster-name> -n <namespace>
```

## Important Notes

- **Master node (homelab-0)**: Runs etcd, upgrade last
- **Longhorn storage**: Verify replicas healthy before draining
- **CNPG PDBs**: Automatically prevent unsafe drains
