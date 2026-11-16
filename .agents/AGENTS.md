# .agents

## Purpose
- Repo-scoped agent skills under `.agents/skills/`, loaded by agent harnesses working in this repo.

## Ownership
- Upstream-vendored skills are pinned in root `skills-lock.json` (source repo, skill path, content hash): `cnpg-database`, `gitops-cluster-debug`, `gitops-knowledge`, `gitops-repo-audit`, `helm-chart-scaffolding`, `k8s-manifest-generator`, `k8s-security-policies`.
- Local skills not in the lock file, owned by this repo: `deactivate-service` (stop or retire Flux apps, optionally removing approved storage), `powercycle-cluster` (node and cluster reboots/power), `upgrade-cluster-nix` (flake, NixOS channel, k3s, devShell tools), `upgrade-cluster-program` (Flux, charts, images via GitOps).

## Local Contracts
- Do not hand-edit vendored skills; local edits break the `skills-lock.json` hash and are lost on update. Re-install from upstream instead.
- Local skills hold procedures only; durable context lives in the nearest DOX AGENTS.md. Keep them consistent with root `AGENTS.md` and `flux/` docs.
- Local skills must not pin tool or platform versions; read them from `flake.nix`/`flake.lock` or the devShell.

## Work Guidance

## Verification
