---
name: upgrade-cluster-program
description: >
  Upgrade software running on the homelab cluster through GitOps: Flux itself
  (flux-operator and FluxInstance), then controller and app Helm charts and images.
  Use after the Flux CLI version changed in the flake, or when bumping a chart or image.
---

# Upgrade programs on the cluster

Flux follows the flake: the `FluxInstance` distribution matches the devShell Flux CLI,
and the flux-operator chart matches nixpkgs `fluxcd-operator`. Rules for each tree
live in the nearest `flux/**/AGENTS.md`. Run from the repo root inside the devShell.

## Flux

1. Read targets from the flake:
   `nix develop -c flux version --client` and
   `nix eval --raw --inputs-from . nixpkgs#fluxcd-operator.version`.
2. Compare with `flux/clusters/production/flux-system/flux-instance.yaml`
   (`distribution.version`) and `flux-operator.yaml` (`semver`). Equal: skip to Charts.
3. Migrate APIs first: `flux migrate -f ./flux` with the new CLI, then
   `flux migrate` against the cluster. Review the diff.
4. Bump the operator `semver` and the `FluxInstance` `distribution.version`.
   Read the Flux release notes for every skipped minor.
5. `./flux/scripts/validate.sh`, commit, push to `main`, then
   `flux reconcile source git flux-system -n flux-system`.
6. Done when `kubectl get fluxinstance -n flux-system` reports Ready on the new version,
   `flux check` passes, and every Kustomization and HelmRelease is Ready.

## Charts and images

One component per commit:
1. Find the newest release; read its release notes and upgrade notes for CRD, value,
   and breaking changes between the pinned and the new version.
2. Bump the pin, adjust values, validate, commit, push, reconcile.
3. Done when its HelmRelease is Ready and its workloads are healthy before the next component.

Stateful components (CNPG operator, Longhorn, Postgres major versions) need the
`powercycle-cluster` preflight green before and after.

## Boundaries

- Inside: Flux alignment to the flake, chart and image bumps within a major version, validation, push, reconcile.
- Outside: major-version jumps of stateful components and Postgres major upgrades; ask first.
- Report each component's old and new version and its health.
