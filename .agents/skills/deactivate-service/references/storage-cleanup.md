# Storage cleanup

Choose this branch only after the user’s retain-or-erase decision. Inventory both
the Kubernetes objects and their backend data; object deletion is not proof of
physical reclamation.

## Retain

Verify PVC owner references, PV reclaim policy, StatefulSet retention, and the
controller/chart’s uninstall behavior before removing their owners or namespace.
Use supported retention controls or an explicitly accepted, verified backup.
Keeping chart files does not preserve stored data. An unmounted PVC is not proof
that its data is unused or disposable.

**Done:** the selected storage or backup remains identifiable and usable for the
agreed restore path; report existing database corruption separately.

## Erase

Freeze the approved PVC/PV UIDs and backend volume IDs before deletion. Verify
there are no remaining workloads, mounts, attachments, or active owners that can
recreate or use them. Delete through normal Kubernetes/storage-controller lifecycle
and watch bounded completion.

Measure separately:
- Requested PVC capacity.
- Backend-reported per-volume allocation, which may include snapshots.
- Physical allocation across current replicas and historical directories.

These are different quantities. Do not multiply configured replica count to claim
actual reclaimed space. A failed node/SSH read means unknown, not zero; use an
authorized alternative such as Kubernetes access or report incomplete coverage.

### Historical Longhorn data

Match candidates to the frozen retired volume IDs, not namespace names or an
unfiltered orphan list. Verify the volume, replica, engine, PV CSI handle, and
VolumeAttachment references are absent, including terminating objects.

Prefer the installed Longhorn version’s supported manual Orphan cleanup. Verify
each candidate’s node, disk identity/path, data directory, and `DataCleanable=True`
before deletion, then verify physical reclamation. A missing manager can leave
data behind even when its Orphan object disappears. Keep global auto-deletion
settings unchanged.

### Offline escalation

If disk pressure prevents controller recovery, confirm filesystem cleanup is within
the approved erasure scope; otherwise ask before proceeding. Obtain storage-specific
review and prepare a task-specific, previewed allowlist. Exclude every volume with
any remaining backend/API reference.

Require exact direct-child paths on the expected filesystem, stable device/inode
identities, and complete mount/open-file/process-mapping checks across namespaces.
Recheck references and identities immediately before each deletion. Incomplete
visibility blocks deletion. Limit cleanup to sufficient recovery space, then let
controllers resume and finish through supported APIs. No broad filesystem recipe
or storage-finalizer bypass belongs in this skill.

**Done:** approved storage objects and scoped data are absent on every relevant
node, unrelated storage identities survive, and reclaimed versus net free space
is reported without conflating concurrent writes or replica rebuilds.
