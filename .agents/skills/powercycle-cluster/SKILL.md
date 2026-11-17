---
name: powercycle-cluster
description: >
  Reboot, power off, or power on homelab k3s nodes safely. Use when restarting
  one node, applying a Colmena change that needs a reboot, or shutting down and
  starting the whole cluster. upgrade-cluster-nix uses it for every node reboot.
---

# Power cycle the cluster

Host facts (IPs, roles, hardware) live in root `AGENTS.md`; CNPG and Longhorn
behaviour lives in `flux/apps/base/AGENTS.md` and `flux/infrastructure/AGENTS.md`.
Run commands from the repo root inside the devShell.

## Preflight (every branch, before each node)

```bash
kubectl get nodes
kubectl get clusters.postgresql.cnpg.io -A
kubectl -n longhorn-system get volumes.longhorn.io -o custom-columns=N:.metadata.name,S:.status.state,R:.status.robustness --no-headers
kubectl get pods -A --field-selector=status.phase!=Running,status.phase!=Succeeded
for h in $(kubectl get nodes -o jsonpath='{..addresses[?(@.type=="InternalIP")].address}'); do ssh root@$h 'hostname; df -h / | tail -1'; done
```

Green means: every node `Ready`, every CNPG cluster `Cluster in healthy state`,
every attached volume `healthy`, no stuck pods, every root disk below 80%.
Stop and diagnose on anything else; a red preflight is how a second node gets lost.

## Branch A: one node (reboot or `colmena apply --reboot`)

1. Preflight green.
2. Move CNPG primaries off the node:
   `kubectl get pods -A -l cnpg.io/instanceRole=primary -o wide`, then for each on the node
   `kubectl cnpg promote <cluster> <instance-on-another-node> -n <ns>`; wait for the cluster to report healthy.
3. Drain, respecting PodDisruptionBudgets:
   `kubectl drain <node> --ignore-daemonsets --delete-emptydir-data --timeout=10m`.
   If a pod blocks, read why; delete it only when it is disposable. A drain stuck only on a
   Longhorn `instance-manager` PDB is safe to continue when no Kubernetes `VolumeAttachment`
   on the node remains.
4. Restart: `ssh root@<ip> reboot`, or `colmena apply --on <node> --reboot` when called for a deploy.
5. Wait for `Ready` and for `/run/flannel/subnet.env` on the node; `Ready` alone does not prove
   pod networking. If the file never appears, read the k3s journal for `failed calling webhook`
   and stop. Then `kubectl uncordon <node>`.
6. Done when preflight is green again, including Longhorn rebuilds finished. Only then start another node.

## Branch B: whole cluster off and on

Off:
1. Preflight green.
2. Hibernate every CNPG cluster for a clean Postgres shutdown:
   `kubectl annotate clusters.postgresql.cnpg.io -A --all cnpg.io/hibernation=on --overwrite`;
   wait until no `cnpg.io/cluster` pods remain.
3. `kubectl cordon` all nodes, then `ssh root@<ip> poweroff` in order homelab-2, homelab-1, homelab-0.

On:
1. Power on all three close together; etcd needs 2 of 3 members before the API answers.
2. Wait for all nodes `Ready`, then `kubectl uncordon` each.
3. `kubectl annotate clusters.postgresql.cnpg.io -A --all cnpg.io/hibernation-`.
4. Done when preflight is green and `flux get kustomizations -A` and `flux get helmreleases -A` are all Ready.

## Boundaries

- Inside: preflight, promote, drain, reboot, uncordon, and waits above; they keep at most one node out at a time.
- Outside: any step while preflight is red, rebooting a second node before the first is green, and Branch B; Branch B needs the user's go-ahead.
- Report each node's before/after state and anything still degraded.
