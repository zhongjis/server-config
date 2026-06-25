# Node upgrade runbook

Before draining any node, check stateful workloads:

```bash
kubectl get nodes
kubectl get clusters.postgresql.cnpg.io -A
kubectl get pods -A --field-selector=status.phase!=Running,status.phase!=Succeeded
```

Upgrade one node at a time:

```bash
node=<homelab-0|homelab-1|homelab-2>
kubectl drain "$node" --ignore-daemonsets --disable-eviction --delete-emptydir-data --force
colmena apply --on "$node" --reboot
kubectl uncordon "$node"
kubectl get nodes
kubectl get clusters.postgresql.cnpg.io -A
```

Do not run `colmena apply` across all nodes while CNPG or other stateful workloads are unhealthy.
