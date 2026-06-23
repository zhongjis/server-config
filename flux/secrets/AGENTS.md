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
- Existing files include legacy app-scoped naming patterns; preserve names unless a rename is explicitly requested.

## File Layout and Naming
- Preferred creation rule: one manually-managed SOPS file per namespace: `production/<namespace>-secrets-flux.yaml`.
- Keep all manually-managed Secrets for the same namespace in that namespace file when practical.
- Legacy files already exist: `*-secrets-fluxcd.yaml`, `*-secrets.yaml`, and app-scoped `*-secrets-flux.yaml`; preserve them unless a rename is explicitly requested.
- Match each Secret's `metadata.namespace`, `metadata.name`, and keys to the consuming HelmRelease `valuesFrom` or manifest.
- Never store CNPG-generated application secrets such as `<app>-cnpg-cluster-app` here.

## Safe Secret Creation Workflow
- Agent prepares manifest shape only: Secret documents, required keys, placeholders, and optional generation-command comments.
- Agent must not ask the user to paste real secret values into chat, logs, or review text.
- Agent must not decrypt, print, summarize, or copy existing secret values.
- If the namespace secret file does not exist, create a placeholder template at `production/<namespace>-secrets-flux.yaml`; mark it not commit-ready until user fills values locally and encrypts it.
- If the namespace secret file already exists and is encrypted, do not edit it directly with placeholder values. Provide a separate snippet/template for the user to merge locally with `sops flux/secrets/production/<namespace>-secrets-flux.yaml`.
- Do not add plaintext templates or snippets to `production/kustomization.yaml`; add the namespace file only after it is encrypted.
- After the user fills values, tell them to encrypt from repo root: `sops --encrypt --in-place flux/secrets/production/<namespace>-secrets-flux.yaml`.
- If generation commands are useful, place them in the template/snippet comments; do not rely on comments surviving as long-term documentation after SOPS edits.

## Encryption Rule
```bash
sops --encrypt --in-place flux/secrets/production/<namespace>-secrets-flux.yaml
```
- `.sops.yaml` encrypts only `data` and `stringData` for `flux/secrets/production/*.yaml`.
- Recipients are the primary age key and the homelab age key.
- Keep non-secret metadata readable so Flux, kustomize, and reviews can inspect resource identity.

## Validation Checklist
- Confirm the file is encrypted before committing: `data` or `stringData` should contain SOPS-encrypted values, not plaintext.
- Confirm `sops` metadata exists and the configured age recipients match `.sops.yaml`.
- Confirm `flux/secrets/production/kustomization.yaml` includes any new encrypted Secret file.
- Confirm the consuming HelmRelease `valuesFrom` or manifest references the correct Secret name and keys.
- Run `./flux/scripts/validate.sh` from the repo root.
- Remember `validate.sh` runs `kubeconform -skip=Secret`; Secret schema and decryption mistakes require manual review.
- If safe and needed, use local SOPS commands only to verify encryption status, not to expose values.

## Always
- Keep Kubernetes Secrets in this subtree SOPS-encrypted.
- Prefer one manually-managed SOPS file per namespace for new secrets.
- Use placeholders and generation comments only; users supply real values locally.
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
