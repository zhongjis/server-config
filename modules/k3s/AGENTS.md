# modules/k3s

> NixOS module guidance for the k3s service and node-level storage support.

## Overview
- `modules/k3s/` owns the NixOS-side k3s server service configuration for all homelab nodes.
- All nodes run `services.k3s.role = "server"`; the master flag only controls cluster initialization and join address behavior.
- This module decrypts the shared `k3s_token` from `../../secrets/homelab.yaml` via sops-nix.
- `longhorn.nix` and `nfs.nix` provide node prerequisites for storage; Flux owns Kubernetes app storage resources.

## Structure
```text
modules/k3s/
├── default.nix    # k3s service, token secret, cluster init/join, labels, flags
├── longhorn.nix   # Longhorn host prerequisites: nfs-utils, open-iscsi, helper symlink
└── nfs.nix        # NFS filesystem/rpcbind support
```

## Where to Look
| Need | Path | Notes |
|------|------|-------|
| k3s service settings | `default.nix` | Main `services.k3s` module. |
| k3s token secret | `default.nix` | `sops.secrets.k3s_token` uses `../../secrets/homelab.yaml`. |
| age key override | `default.nix` | `sops.age.keyFile = "keys.txt"` is intentionally local here. |
| Master/join logic | `default.nix` | Uses `custHostConfig.isK3sMaster` and `custHostConfig.masterAddr`. |
| Node labels | `default.nix` | Passed through from `custHostConfig.nodeLabels`. |
| Longhorn host support | `longhorn.nix` | open-iscsi and NFS userland prerequisites. |
| NFS host support | `nfs.nix` | NFS filesystem and rpcbind support. |

## k3s Flag Rules
- Keep `--disable servicelb` and `--disable traefik`; Flux supplies MetalLB and ingress-nginx.
- Keep control-plane metrics bind addresses explicit when changing metrics exposure:
  - `--kube-controller-manager-arg bind-address=0.0.0.0`
  - `--kube-proxy-arg metrics-bind-address=0.0.0.0`
  - `--kube-scheduler-arg bind-address=0.0.0.0`
- Keep `--etcd-expose-metrics true` unless the monitoring design changes.
- Keep kubelet pointed at `/run/k3s/containerd/containerd.sock` unless k3s/containerd integration changes.
- Treat `extraFlags` as cluster behavior; validate effects across every node role before changing it.

## Token and Master Gotchas
- The token file comes from `config.sops.secrets.k3s_token.path`; do not inline the token or commit decrypted secrets.
- `sops.age.keyFile = "keys.txt"` overrides the repo-wide default; preserve it unless changing target secret layout deliberately.
- `clusterInit = custHostConfig.isK3sMaster`; exactly the intended bootstrap node should set this true.
- Master nodes use an empty `serverAddr`; non-master server nodes join `https://${masterAddr}:6443`.
- `custHostConfig` flows from the hive wiring; check `flake.nix` and `lib/defaults.nix` before changing its fields.

## Always
- Preserve the `custHostConfig`-driven master, join address, and node label flow.
- Keep module-level storage support separate from Flux-managed StorageClasses, PVCs, and app manifests.
- Evaluate or build the affected NixOS configuration before applying it to nodes.
- Check secret key availability before changes that depend on SOPS decryption.

## Ask First
- Changing which node initializes the cluster or how workers/servers join the cluster.
- Changing the k3s token source, SOPS key file path, or secret file layout.
- Removing or replacing the Longhorn/NFS host prerequisites.
- Changing metrics bind addresses or disabling etcd metrics.

## Never
- Do not enable k3s `servicelb` or `traefik` from this module.
- Do not add Kubernetes app storage resources here; keep them under Flux ownership.
- Do not hardcode host-specific labels, IPs, or tokens in this module.
- Do not commit decrypted `secrets/homelab.yaml` content or ad-hoc plaintext secrets.
