<!-- dox-source: agent0ai/dox@main sha256:e1123d740736d6792efc4d11afa5a6a0f34610131ee7714ccf592f007b9bc3ea -->

# DOX framework

- DOX is highly performant AGENTS.md hierarchy installed here
- Agent must follow DOX instructions across any edits

## Core Contract

- AGENTS.md files are binding work contracts for their subtrees
- Work products, source materials, instructions, records, assets, and durable docs must stay understandable from the nearest applicable AGENTS.md plus every parent AGENTS.md above it

## Read Before Editing

1. Read the root AGENTS.md
2. Identify every file or folder you expect to touch
3. Walk from the repository root to each target path
4. Read every AGENTS.md found along each route
5. If a parent AGENTS.md lists a child AGENTS.md whose scope contains the path, read that child and continue from there
6. Use the nearest AGENTS.md as the local contract and parent docs for repo-wide rules
7. If docs conflict, the closer doc controls local work details, but no child doc may weaken DOX

Do not rely on memory. Re-read the applicable DOX chain in the current session before editing.

## Update After Editing

Every meaningful change requires a DOX pass before the task is done.

Update the closest owning AGENTS.md when a change affects:

- purpose, scope, ownership, or responsibilities
- durable structure, contracts, workflows, or operating rules
- required inputs, outputs, permissions, constraints, side effects, or artifacts
- user preferences about behavior, communication, process, organization, or quality
- AGENTS.md creation, deletion, move, rename, or index contents

Update parent docs when parent-level structure, ownership, workflow, or child index changes. Update child docs when parent changes alter local rules. Remove stale or contradictory text immediately. Small edits that do not change behavior or contracts may leave docs unchanged, but the DOX pass still must happen.

## Hierarchy

- Root AGENTS.md is the DOX rail: project-wide instructions, global preferences, durable workflow rules, and the top-level Child DOX Index
- Child AGENTS.md files own domain-specific instructions and their own Child DOX Index
- Each parent explains what its direct children cover and what stays owned by the parent
- The closer a doc is to the work, the more specific and practical it must be

## Child Doc Shape

- Create a child AGENTS.md when a folder becomes a durable boundary with its own purpose, rules, responsibilities, workflow, materials, or quality standards
- Work Guidance must reflect the current standards of the project or user instructions; if there are no specific standards or instructions yet, leave it empty
- Verification must reflect an existing check; if no verification framework exists yet, leave it empty and update it when one exists

Default section order:

- Purpose
- Ownership
- Local Contracts
- Work Guidance
- Verification
- Child DOX Index

## Style

- Keep docs concise, current, and operational
- Document stable contracts, not diary entries
- Put broad rules in parent docs and concrete details in child docs
- Prefer direct bullets with explicit names
- Do not duplicate rules across many files unless each scope needs a local version
- Delete stale notes instead of explaining history
- Trim obvious statements, repeated rules, misplaced detail, and warnings for risks that no longer exist

## Closeout

1. Re-check changed paths against the DOX chain
2. Update nearest owning docs and any affected parents or children
3. Refresh every affected Child DOX Index
4. Remove stale or contradictory text
5. Run existing verification when relevant
6. Report any docs intentionally left unchanged and why

## User Preferences

When the user requests a durable behavior change, record it here or in the relevant child AGENTS.md

- Single production cluster only. There is no staging cluster; do not add staging overlays, entrypoints, or environments.
- Tool and platform versions come from `flake.lock`. Docs and skills must not pin version numbers; read them from the flake or devShell instead.
- The Flux CLI, flux-operator MCP server, and on-cluster Flux (FluxInstance distribution and flux-operator chart) follow the nixpkgs versions in `flake.lock`.
- Keep durable context in the DOX AGENTS.md nearest its implementation; skills hold procedures only.

## Child DOX Index

Direct children of the root. Each child indexes its own subtree.

- `flux/AGENTS.md` — Kubernetes/Flux GitOps subsystem; indexes `apps/`, `clusters/`, `infrastructure/`, `monitoring/`, `secrets/`.
- `hosts/k3s/AGENTS.md` — node-level NixOS host config, disko, hardware configs.
- `modules/k3s/AGENTS.md` — k3s service module and flags.
- `tools/paperclip-agent-shim/AGENTS.md` — Paperclip agent shim (Go), its runtime image in `docker/paperclip-agent-runtime/`, and the GHCR build workflow.
- `.agents/AGENTS.md` — repo agent skills: vendored ones pinned by `skills-lock.json`, plus local procedure skills.

Owned by root (no child doc): `flake.nix`, `flake.lock`, `lib/`, `modules/{default,user,sops}.nix`, `secrets/homelab.yaml`, `.sops.yaml`, `.github/workflows/{test,e2e}.yaml`, `renovate.json`, `mcp.json` + `.pi/mcp.json` + `MCP-RUNBOOK.md`, `README.md`, `UPGRADE.md`, `reports/` (static HTML research/plan reports; not consumed by any build).

Ignored local tool state, not part of the DOX tree: `.codex/`, `.omo/`, `.pi/`, `.sisyphus/`, `.gitnexus/`, `.codegraph/`, `.direnv/`.

# server-config

> Root instructions for NixOS hosts + repo-wide workflows. For Kubernetes manifests, read `flux/AGENTS.md` first.

## Overview

- Homelab infrastructure repo: Colmena-managed NixOS k3s nodes + Flux-managed Kubernetes apps.
- Two domains: root NixOS host config; `flux/` GitOps manifests reconciled by Flux v2.
- Production Flux tracks remote GitHub `ssh://git@github.com/zhongjis/server-config` branch `main`; local commits do not reconcile until pushed.
- `nix develop` (direnv `use flake`) provides `kubeconform`, `flux`, and `flux-operator-mcp` from `flake.lock`.

## Structure

```
./
├── flake.nix              # Colmena hive: homelab-0/1/2
├── lib/defaults.nix       # mkHiveSpecialArgs + mkHiveK3s wrappers
├── hosts/k3s/             # shared node config, disko, hardware configs
├── modules/               # NixOS modules: cache, users, sops, k3s
├── secrets/homelab.yaml   # SOPS-encrypted NixOS secrets
├── flux/                  # Kubernetes/Flux subsystem; has its own AGENTS.md
├── tools/                 # paperclip-agent-shim Go binary
├── docker/                # paperclip-agent-runtime image Dockerfile
├── reports/               # static HTML reports
├── .agents/skills/        # vendored agent skills (skills-lock.json)
└── .github/workflows/     # Flux validation, Kind e2e, Paperclip image build
```

## Where to Look

| Task                  | Location                                                       | Notes                                                                     |
| --------------------- | -------------------------------------------------------------- | ------------------------------------------------------------------------- |
| Add/change k3s node   | `flake.nix`, `hosts/k3s/`                                      | `custHostConfig` comes from `lib/defaults.nix`.                           |
| Change k3s flags      | `modules/k3s/default.nix`                                      | servicelb/traefik disabled; metrics exposed.                              |
| Change users/SOPS     | `modules/user.nix`, `modules/sops.nix`, `secrets/homelab.yaml` | Root secrets differ from Flux secrets.                                    |
| Deploy NixOS          | `flake.nix`                                                    | Use Colmena; build before apply when possible.                            |
| Node maintenance      | `UPGRADE.md`                                                   | Preflight → move CNPG primaries → drain → apply/reboot → verify.          |
| Kubernetes apps/infra | `flux/`                                                        | Read `flux/AGENTS.md`; run `./flux/scripts/validate.sh`.                  |
| CI behavior           | `.github/workflows/*.yaml`                                     | Flux manifests/e2e + Paperclip runtime image; no NixOS CI build.          |
| Renovate rules        | `renovate.json`                                                | Nix + Kubernetes managers; Flux itself follows `flake.lock`.              |
| MCP config            | `mcp.json`, `.pi/mcp.json` (Pi)                                | Read-only Flux MCP via `nix run .#flux-operator-mcp`; lazy.               |

## Host Map

| Host        | Role                         | IP               | Hardware                                  | Notes                                                                 |
| ----------- | ---------------------------- | ---------------- | ----------------------------------------- | --------------------------------------------------------------------- |
| `homelab-0` | k3s server, etcd, clusterInit | `192.168.50.104` | Lenovo ThinkCentre M70q, i7-10700T, 32G   | `isMaster = true`, label `n8n-node=true`.                             |
| `homelab-1` | k3s server, etcd             | `192.168.50.103` | Lenovo ThinkCentre M70q, i5-10500T, 32G   | Joins `https://192.168.50.104:6443`.                                  |
| `homelab-2` | k3s server, etcd             | `192.168.50.105` | HP EliteDesk 800 G4 DM 35W, i5-8500T      | External power adapter; history of abrupt power loss. Smaller disk.   |

- All three nodes are k3s servers and etcd voters; etcd survives one node down. Colmena `master`/`worker` tags are deploy tags only.

## Code Map

| Symbol / Pattern            | Type          | Location                                                 | Role                                                             |
| --------------------------- | ------------- | -------------------------------------------------------- | ---------------------------------------------------------------- |
| `mkHiveSpecialArgs`         | Nix helper    | `lib/defaults.nix`                                       | Builds `custHostConfig` for modules.                             |
| `mkHiveK3s`                 | Nix helper    | `lib/defaults.nix`                                       | Adds deployment target + sops-nix + disko imports.               |
| `custHostConfig`            | special arg   | `hosts/k3s/configuration.nix`, `modules/k3s/default.nix` | Hostname, master flag, join address, labels.                     |
| `services.k3s.extraFlags`   | k3s tuning    | `modules/k3s/default.nix`                                | Disables k3s defaults; exposes metrics endpoints.                |
| `.sops.yaml` creation rules | secret policy | `.sops.yaml`                                             | Root secrets: primary key; Flux secrets: primary + homelab keys. |

## Commands

```bash
# NixOS / Colmena
colmena build
colmena apply
colmena apply --on homelab-0
colmena apply --on homelab-1
colmena apply --on homelab-2
colmena apply --on homelab-0 --reboot

# Node maintenance: follow UPGRADE.md (one node at a time)

# NixOS secrets
sops secrets/homelab.yaml
sops --age=age1gff6wle45ktarxc89vfqnq6qawwjcxd5jed4jnuhhddpeqxz6d7q8wq8gn --encrypt --in-place secrets/homelab.yaml

# Flux validation from repo root
./flux/scripts/validate.sh
# If kubeconform is missing locally
nix shell nixpkgs#kubeconform -c ./flux/scripts/validate.sh
kustomize build ./flux/apps/production
kustomize build ./flux/apps/production-db
kustomize build ./flux/apps/production-nondb
```

## Always

- For Kubernetes, Flux, HelmRelease, Kustomization, Secret, CNPG, or kubectl work: read `flux/AGENTS.md` first.
- Keep `system.stateVersion = "24.05"` unless explicitly doing a NixOS state migration.
- Keep k3s `servicelb` and `traefik` disabled; Flux supplies MetalLB + ingress-nginx.
- Build or evaluate before applying NixOS changes when possible: `colmena build`.
- Preserve `custHostConfig` flow: `flake.nix` → `lib/defaults.nix` → host/modules.
- Verify age key availability before SOPS/Colmena deploys: `~/.config/sops/age/keys.txt` locally; target key copied by nixos-anywhere.

## Ask First

- Changing node IPs, hostnames, or master election.
- Changing `system.stateVersion`, nixpkgs channel, disk layout, or k3s token.
- Running `colmena apply` against all nodes when workloads are stateful.
- Editing Kubernetes resources outside GitOps reconciliation.

## Never

- Do not reintroduce `flux bootstrap` output (`gotk-components.yaml`, `gotk-sync.yaml`); flux-operator installs Flux from `flux/clusters/production/flux-system/`.
- Do not drain with `--disable-eviction`; it bypasses CNPG PodDisruptionBudgets.
- Do not rely on README nixos-anywhere examples without checking `flake.nix`; current docs have stale IP/hardware-config examples.
- Do not commit decrypted `secrets/homelab.yaml` or ad-hoc plaintext Kubernetes Secrets.
- Do not enable k3s servicelb/traefik unless also redesigning Flux infrastructure.

## Gotchas

- Disko device is hardcoded: `/dev/nvme0n1` in `hosts/k3s/configuration.nix`. Verify before nixos-anywhere.
- Hardware config inclusion is filename-sensitive: `hardware-configuration-${hostName}.nix`; mismatches silently skip.
- `modules/k3s/default.nix` sets `sops.age.keyFile = "keys.txt"`, overriding the absolute default from `modules/sops.nix`.
- k3s metrics bind to `0.0.0.0`; firewall assumes trusted LAN.
- Older AGENTS content referenced absent OpenCode context files; do not add path references unless files exist.
