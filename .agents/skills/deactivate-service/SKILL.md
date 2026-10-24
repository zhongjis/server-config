---
name: deactivate-service
description: >
  Deactivate or retire Flux-managed applications in this repository while keeping
  their charts and configuration reusable. Use when stopping an app with data
  retained, uninstalling an app while retaining its data, or removing an app and
  explicitly approved persistent storage. Not for powering down NixOS nodes.
---

# Deactivate a service

Keep the deployment recipe; change whether production enrolls or runs it. Follow
`flux/AGENTS.md` and the affected subtree instructions. Use
`flux/apps/AGENTS.md` to locate production owners rather than assuming one overlay.

## 1. Establish the boundary

Identify the app, cluster context, desired end state, and storage decision:

| Mode | Runtime outcome | Data outcome |
|---|---|---|
| Pause | No app execution; resources remain available to resume | Retained |
| Remove, retain data | App runtime resources removed | Explicitly protected storage or verified backup |
| Retire and erase | App runtime resources and approved app-owned storage removed | Permanent deletion acknowledged |

Default to retaining data when the user has not decided. Removing PVCs and
restoring charts later produces a fresh installation, not a data restore.
Proposal-only requests remain read-only. With implementation authorized, prepare
scoped local changes. Obtain any missing production, publication, or deletion
authorization before the corresponding action;
the skill invocation itself grants none. Carry out already-approved actions
without asking the same question again.

**Done:** the target and mode are concrete, with no inferred permission to erase data.

## 2. Ground ownership and dependencies

Inspect both Git and the live cluster. Build a bounded inventory of:
- Every active owner: legacy and split app overlays, secrets, and dedicated operators.
- Workloads, autoscalers, app CRs, databases, execution namespaces, and controller finalizers.
- PVC/PV names and UIDs, reclaim policies, storage volume IDs, and baseline allocation when erasing data.
- Shared dependencies and unrelated resource identities that must survive.

Keep secret values encrypted or unread. A namespace or operator is removable only
when its contents and consumers belong to the retirement scope.

**Done:** every intended removal has an owner, and shared resources have an explicit boundary.

## 3. Change the desired state

For **pause**, persist a reversible stop through the app/controller configuration.
Stop the complete stack, including autoscalers, bundled databases, workers, object
storage, and dedicated database pods. Suspending Flux or a HelmRelease only stops
reconciliation; it does not stop existing workloads.

For **removal**, disable enrollment in every active owner, including encrypted
secret includes and obsolete health checks. Preserve base manifests, chart pins,
values, and encrypted secret files. Remove temporary shutdown patches from the
now-unenrolled base so re-enrollment can start it normally. Keep shared controllers.

Validate with `./flux/scripts/validate.sh` and render the affected production
overlays and retained base tiers at their actual Kustomization roots.

**Done:** pause renders a complete stop, or removal renders no retired app enrollment
while retained bases still render a usable installation.

## 4. Apply and prove convergence

Follow repository rules for legacy-owner suspension and approved commit/push.
Production follows the remote Git revision, not local edits. Verify relevant
app, root, and secret owners applied that revision; restore any temporary suspension.
A blocked owner is a deployment blocker, not permission to bypass its dependencies.

When pruning is disabled, enrollment removal leaves existing resources behind.
After proving no active owner can recreate them, explicitly retire the app-owned
HelmReleases/CRs through their normal lifecycle. Keep a required operator available
until its CR cleanup finishes. For retained data, prove storage protection before
uninstall or namespace deletion.

If readiness disagrees with runtime state, hibernation stalls, or a finalizer blocks
cleanup, read [Controller recovery](references/controller-recovery.md).
For PVC deletion or historical replicas, read [Storage cleanup](references/storage-cleanup.md).

**Done:** live workloads match the selected mode; a Ready condition alone is insufficient.

## 5. Verify and hand off

Prove the selected outcome, not merely successful commands:
- Pause: no app execution or autoscaler-driven revival; retained storage identities survive.
- Removal: no scoped runtime resources, dedicated databases, or execution namespaces remain or reappear.
- Erasure: approved PVC/PVs, storage resources, and scoped historical data are gone.
- Shared resources remain, and temporarily suspended owners are restored.

Report the applied revision, retained configuration paths, measured storage outcome,
residual blockers, and the enrollment/operator steps needed to re-enable. Label
unknown measurements honestly; CPU usage does not establish watts saved.

Stop when the approved result is proven. Repairing unrelated cluster faults or
cleaning other orphan data requires separate scope.
