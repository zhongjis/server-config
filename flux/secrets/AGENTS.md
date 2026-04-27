# flux/secrets

## Overview
- This subtree holds SOPS-encrypted Kubernetes `Secret` manifests reconciled by Flux.
- Secrets here are application or platform inputs consumed by HelmReleases, Kustomizations, or controllers.
- Do not decrypt, print, summarize, or copy secret values while editing this tree.
- CNPG-generated application secrets such as `<app>-cnpg-cluster-app` are created by the operator and are not stored here.

## Structure
```text
flux/secrets/
└── production/
    ├── kustomization.yaml
    └── *-secrets*.yaml
```
- `production/kustomization.yaml` lists the encrypted Secret manifests Flux should apply.
- Existing files include preferred and legacy naming patterns; preserve names unless a rename is explicitly requested.

## Naming
- New preferred app secret manifest name: `<app>-secrets-flux.yaml`.
- Legacy names already exist: `*-secrets-fluxcd.yaml` and `*-secrets.yaml`.
- Match the Kubernetes `metadata.name` expected by the consuming HelmRelease or manifest.
- App HelmReleases commonly consume these Secrets through `valuesFrom`; update both sides only when requested.

## Encryption Command
```bash
sops --age=age12x6hk7hpxmemtv8huugzver7mq6xapd42vq899azenrlp77e4sjqcs7745,age1gff6wle45ktarxc89vfqnq6qawwjcxd5jed4jnuhhddpeqxz6d7q8wq8gn \
  --encrypted-regex '^(data|stringData)$' \
  --encrypt --in-place flux/secrets/production/<app>-secrets-flux.yaml
```
- `.sops.yaml` encrypts only `data` and `stringData` for `flux/secrets/production/*.yaml`.
- Recipients are the primary age key and the homelab age key.
- Keep non-secret metadata readable so Flux, kustomize, and reviews can inspect resource identity.

## Validation Checklist
- Confirm the file is encrypted before committing: `data` or `stringData` should contain SOPS-encrypted values, not plaintext.
- Confirm `sops` metadata exists and the configured age recipients match `.sops.yaml`.
- Confirm `flux/secrets/production/kustomization.yaml` includes any new Secret file.
- Confirm the consuming HelmRelease `valuesFrom` or manifest references the correct Secret name and keys.
- Run `./flux/scripts/validate.sh` from the repo root.
- Remember `validate.sh` runs `kubeconform -skip=Secret`; Secret schema and decryption mistakes require manual review.
- If safe and needed, use local SOPS commands only to verify encryption status, not to expose values.

## Always
- Keep Kubernetes Secrets in this subtree SOPS-encrypted.
- Use `<app>-secrets-flux.yaml` for new app secret manifests.
- Preserve the `.sops.yaml` policy for `flux/secrets/production/*.yaml` unless the user explicitly asks to change it.
- Check the consuming app overlay before changing Secret names or keys.

## Ask First
- Decrypting, rotating, replacing, or removing real secret values.
- Renaming Secret manifests or Kubernetes `metadata.name` values used by live apps.
- Changing `.sops.yaml` creation rules, age recipients, or encryption scope.
- Moving secrets between app-local paths and `flux/secrets/production/`.

## Never
- Never commit plaintext Kubernetes Secret values or decrypted SOPS output.
- Never create new plaintext app-local `Secret.yaml` files; Homepage has a legacy app-local exception only.
- Never store CNPG-generated secrets here.
- Never rely on kubeconform to validate encrypted Secret contents.

## Gotchas
- `validate.sh` skips all `Secret` resources, so a passing validation run does not prove secrets decrypt or match expected keys.
- `stringData` and `data` are encrypted wholesale by the current SOPS rule; avoid placing review-critical non-secret data under those fields.
- Legacy `*-secrets-fluxcd.yaml` and `*-secrets.yaml` files remain in use; do not rename them opportunistically.
- Flux applies these manifests from Git, so live-only `kubectl create secret` changes will drift or be overwritten.
