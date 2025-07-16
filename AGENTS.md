# AGENTS.md

This file provides guidance for agentic coding agents working with this homelab infrastructure repository.

## Build/Test/Lint Commands

- **Validate all manifests**: `./flux/scripts/validate.sh` (validates YAML syntax and Kubernetes manifests)
- **Build NixOS config**: `nix build .#nixosConfigurations.homelab-0.config.system.build.toplevel`
- **Deploy to host**: `nixos-rebuild switch --flake .#homelab-1 --target-host root@192.168.50.184`
- **Validate single kustomization**: `kustomize build ./flux/apps/staging | kubeconform -strict -ignore-missing-schemas`
- **Check Flux status**: `flux check --pre` and `flux get all --all-namespaces`
- **Test single app**: `kustomize build ./flux/apps/base/<app> | kubeconform -strict -ignore-missing-schemas`
- **Validate single YAML**: `yq e 'true' file.yaml` (syntax check) and `kubeconform -skip=Secret file.yaml`

## Code Style Guidelines

- **NixOS**: Use 2-space indentation, follow existing module patterns, import order: system modules first, then local modules
- **YAML**: Use 2-space indentation, kebab-case for keys, follow Kubernetes resource naming conventions
- **File naming**: Use kebab-case for YAML files, camelCase for Nix attributes, descriptive names matching resource types
- **Secrets**: Always encrypt with SOPS before committing: `sops --age=<key> --encrypt --encrypted-regex '^(data|stringData)$' --in-place file.yaml`
- **Kustomization**: Group resources logically, use base/overlay pattern, maintain consistent resource ordering
- **Comments**: Minimal comments in Nix, use NOTE: prefix for important clarifications
- **Error handling**: Validate all YAML with the validation script before changes, test NixOS builds locally first
- **Types**: Use explicit types in Nix where helpful, follow existing patterns for Kubernetes resource definitions
- **Imports**: In Nix files, import system modules first, then local modules; in kustomizations, maintain alphabetical order

## Repository Structure

This is a GitOps homelab managing NixOS hosts and Kubernetes applications via Flux CD. Always validate changes with the provided scripts before committing.