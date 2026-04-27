# hosts/k3s

> Node-level NixOS host configuration for k3s machines. This file covers local host wiring only; see root `AGENTS.md` for repo-wide workflow and `modules/k3s/` for k3s service behavior.

## Overview
- Shared configuration for homelab k3s NixOS nodes lives in `configuration.nix`.
- Disk layout is defined by `disko-config.nix` and imported with a hardcoded device.
- Per-host hardware files are optional and selected by hostname.
- Host identity comes from `custHostConfig.hostName`, passed through the flake/lib helper flow.

## Structure
```
hosts/k3s/
├── configuration.nix                         # shared host config for all k3s nodes
├── disko-config.nix                          # disk layout used by nixos-anywhere/Disko
├── hardware-configuration-homelab-0.nix      # optional host-specific hardware config
├── hardware-configuration-homelab-1.nix      # optional host-specific hardware config
└── hardware-configuration-homelab-2.nix      # optional host-specific hardware config
```

## Where to Look
| Need | File | Notes |
|------|------|-------|
| Shared node imports/settings | `configuration.nix` | Imports qemu guest, not-detected, Disko, root modules, user, k3s, and SOPS modules. |
| Disk layout/device | `disko-config.nix` plus import in `configuration.nix` | Device is currently passed as `/dev/nvme0n1`. |
| Host-specific hardware | `hardware-configuration-${custHostConfig.hostName}.nix` | Included only if the exact filename exists. |
| k3s service options | `../../modules/k3s/` | Keep service flag details documented there, not here. |
| User and SOPS host integration | `../../modules/user.nix`, `../../modules/sops.nix` | Root NixOS secrets, not Flux Kubernetes secrets. |

## Host Config Rules
- Preserve `custHostConfig` as the source of `networking.hostName`.
- Keep `time.timeZone = "America/Los_Angeles"` unless the site timezone changes intentionally.
- Keep `system.stateVersion = "24.05"` unless explicitly performing a NixOS state migration.
- Keep qemu guest and not-detected imports unless replacing the virtualization/install baseline deliberately.
- Keep the Disko import local and explicit; verify the target block device before imaging or nixos-anywhere.
- Hardware configs are optional; adding one requires the exact `hardware-configuration-<host>.nix` naming pattern.
- Firewall changes belong in `configuration.nix` only when they are node-level requirements.
- Current node firewall allows TCP `2379 2380 2381 6443 9100 10249 10250 10257 10259 5001 6443` and UDP `8472 51820 51821`.

## Ask First
- Changing disk device names, partition layout, or Disko behavior.
- Changing hostnames, node IP assumptions, or the `custHostConfig` flow.
- Changing `system.stateVersion`.
- Removing SOPS, user, root module, or k3s module imports.
- Broadening firewall exposure beyond known LAN/node requirements.

## Never
- Do not hardcode per-node hostnames in `configuration.nix`; use `custHostConfig.hostName`.
- Do not assume `hardware-configuration-*.nix` files load unless their filenames match exactly.
- Do not run imaging/deploy commands against `/dev/nvme0n1` without verifying the target device.
- Do not duplicate detailed k3s service flags here; keep that in `modules/k3s/`.
- Do not change `stateVersion` as part of routine upgrades.

## Gotchas
- The Disko device is hardcoded at the import site as `/dev/nvme0n1`, not discovered dynamically.
- Missing hardware config files are silently skipped by `lib.optional` and `builtins.pathExists`.
- TCP port `6443` appears twice in the current allowed list; avoid cleanup unless requested.
- This directory configures host-level NixOS concerns; Kubernetes manifests and Flux resources live under `flux/`.
