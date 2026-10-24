# Controller recovery

Use this branch when configured deactivation has not produced the selected live state.
Read current status, generation, events, and bounded logs before choosing a recovery.
Verify unfamiliar flags with the installed CLI’s `--help`; use the installed controller’s
API/schema and versioned documentation rather than assuming examples match.

## Ready but still running

Check the pushed source revision, every owner’s applied revision/inventory, and the
HelmRelease’s observed generation and release revision. Inspect actual replicas,
autoscalers, pods, and the stored Helm manifest. A successful reconciliation can
report an unchanged release without applying the intended runtime transition.

Reconcile only the affected owner/release after identifying the mismatch. Use a
forced Helm reconciliation only when inspection establishes that an approved
rendered change was skipped and an upgrade is appropriate; it is not a general retry.

**Done:** the intended runtime transition is observed, not just another Ready condition.

## Database hibernation blocked

Confirm the installed database operator supports the chosen hibernation mechanism.
Check whether disk-space or recovery gates return before the hibernation handler.
CNPG can stop at a low-disk gate without removing pods; confirm the installed
version’s behavior in logs or source rather than treating an annotation as proof.

If logs establish this failure, prefer documented per-cluster controls. A supported
reconciliation pause can prevent replacements, but does not stop existing pods.
Before normally deleting only the approved database pods, observe a fresh,
cluster-specific operator acknowledgment of the pause and verify PVC ownership
and retention. Record how to remove the pause when resuming. Preserve data unless
erasure was approved; deactivation is not checkpoint or WAL recovery.

**Done:** database pods stop without replacements, with the approved data outcome.

## Missing operator or stuck finalizer

Identify which controller owns the finalizer and whether it is available. Prefer
normal controller cleanup. If the operator is already absent, enumerate and finish
its scoped child resources, execution namespaces, and dedicated cluster RBAC first.
Remove only the understood app finalizer after its cleanup obligations are satisfied;
use UID/finalizer preconditions to avoid modifying a changed object.

Leave namespace and storage-protection finalizers to their controllers. Preserve
shared CRDs; remove dedicated CRDs only after verifying no remaining CR consumers
and that retained configuration can reinstall them.

**Done:** cleanup completes without orphaned dependents or weakened shared protection.
