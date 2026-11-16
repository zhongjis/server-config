# .agents

## Purpose
- Repo-scoped agent skills under `.agents/skills/`, loaded by agent harnesses working in this repo.

## Ownership
- Upstream-vendored skills are pinned in root `skills-lock.json` (source repo, skill path, content hash): `cnpg-database`, `gitops-cluster-debug`, `gitops-knowledge`, `gitops-repo-audit`, `helm-chart-scaffolding`, `k8s-manifest-generator`, `k8s-security-policies`.
- Local skills not in the lock file, owned by this repo: `homelab` (node power/Colmena/upgrade/CNPG maintenance), `deactivate-service` (stop or retire Flux apps, optionally removing approved storage).

## Local Contracts
- Do not hand-edit vendored skills; local edits break the `skills-lock.json` hash and are lost on update. Re-install from upstream instead.
- Local skills must stay consistent with root `AGENTS.md`, `UPGRADE.md`, and `flux/` docs; update the skill when those workflows change.

## Work Guidance

## Verification
