# Node upgrade runbook

Work on one node at a time. Do not start while any check below fails.

## Preflight

```bash
kubectl get nodes
kubectl get clusters.postgresql.cnpg.io -A
kubectl -n longhorn-system get volumes.longhorn.io -o custom-columns=N:.metadata.name,S:.status.state,R:.status.robustness
kubectl get pods -A --field-selector=status.phase!=Running,status.phase!=Succeeded
```

- All nodes `Ready`; every CNPG cluster `Cluster in healthy state`.
- Every attached Longhorn volume `healthy`.

## Per node

```bash
node=<homelab-0|homelab-1|homelab-2>

# Move each CNPG primary off the node first
kubectl get pods -A -l cnpg.io/instanceRole=primary -o wide | grep "$node"
kubectl cnpg promote <cluster> <replica-pod-on-another-node> -n <namespace>

# Drain respecting PodDisruptionBudgets (never --disable-eviction)
kubectl drain "$node" --ignore-daemonsets --delete-emptydir-data

colmena apply --on "$node" --reboot
kubectl uncordon "$node"
```

Before the next node, rerun preflight and wait until CNPG clusters and Longhorn volumes are healthy again.

Do not run `colmena apply` across all nodes while CNPG or other stateful workloads are unhealthy.
