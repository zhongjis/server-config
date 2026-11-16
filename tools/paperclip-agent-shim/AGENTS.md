# tools/paperclip-agent-shim

## Purpose
- Go entrypoint binary for the Paperclip agent runtime image.
- Reads a runtime command spec JSON (default `/run/paperclip/runtime-command.json`), resolves `command` on `PATH`, then `syscall.Exec`s it so Kubernetes signals reach the adapter directly.

## Ownership
- This doc also owns `docker/paperclip-agent-runtime/` and `.github/workflows/paperclip-codex-runtime.yaml`; they exist only to build and ship this shim.
- Kubernetes deployment of Paperclip lives in `flux/apps/base/paperclip/`; follow `flux/` docs there.

## Local Contracts
- Spec shape: `RuntimeCommandSpec` in `runtime_command.go` (`command` required; `args`, `detectCommand`, `installCommand` optional). Empty `command` is an error.
- Exit codes: `2` spec unreadable/invalid, `127` command not on `PATH`, `126` exec failed.
- Image: `docker/paperclip-agent-runtime/Dockerfile.codex` builds the shim with `CGO_ENABLED=0`, installs `@openai/codex`, runs as UID/GID `1000` under `tini`, `CMD` is the shim.
- Build context is the repo root; `Dockerfile.codex.dockerignore` admits only `tools/paperclip-agent-shim/**`. New shim inputs outside that path need a dockerignore change.
- CI pushes `ghcr.io/<owner>/paperclip-agent-runtime-codex:sha-<sha>` on `main` pushes touching the shim, Dockerfile, or workflow; `workflow_dispatch` can add a version tag and `latest`.

## Work Guidance

## Verification
```bash
cd tools/paperclip-agent-shim && nix shell nixpkgs#go -c go test ./...
```
