---
name: upgrade-cluster-nix
description: >
  Upgrade the homelab's Nix-managed layer: flake inputs, the NixOS channel, k3s,
  and the devShell tools (Flux CLI, flux-operator MCP, colmena). Use when running
  `nix flake update`, moving to a new NixOS release, or upgrading k3s.
---

# Upgrade the Nix layer

Every version comes from `flake.nix` and `flake.lock`; read versions from the
flake, never from memory or this file. Run from the repo root.

## Steps

1. **Target.** For a channel move, set `inputs.nixpkgs.url` in `flake.nix` to the
   newest `nixos-YY.MM` release. A channel change is Ask First in root `AGENTS.md`
   unless the user already chose the target. Then `nix flake update`.
2. **Build.** `colmena build` must succeed for all nodes. Fix evaluation errors
   and renamed options at their source module; keep `system.stateVersion` unchanged.
3. **k3s skew.** Compare running vs built:
   `kubectl get nodes -o custom-columns=N:.metadata.name,V:.status.nodeInfo.kubeletVersion`
   vs `nix eval --raw .#nixosConfigurations.homelab-0.config.services.k3s.package.version`.
   More than one minor apart: pin an intermediate `k3s_1_XX` package and upgrade in two passes.
4. **Snapshot.** on homelab-0 (IP in root `AGENTS.md`): `ssh root@<ip> k3s etcd-snapshot save --name pre-upgrade`.
5. **Roll.** Commit and push the flake change, then deploy one node at a time in
   order homelab-2, homelab-1, homelab-0 with the `powercycle-cluster` skill,
   Branch A, using `colmena apply --on <node> --reboot`.
6. **Verify.** Every node reports the built k3s version and preflight is green.
7. **Hand off.** If the Flux CLI version changed (`nix develop -c flux version --client`),
   run the `upgrade-cluster-program` skill so the cluster's Flux follows it.

## Boundaries

- Inside: `nix flake update`, builds, module fixes for renamed options, and the rolling deploy once the target is set.
- Outside: `colmena apply` on several nodes at once, changing `stateVersion`, disk layout, or k3s token.
- Report old and new versions for nixpkgs, k3s, and the devShell tools, plus anything left degraded.
