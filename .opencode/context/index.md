# OpenCode Context Index

This repository uses OpenCode standards for consistent agent interactions and documentation.

## Core Standards

### Agent Rules & Guidelines
- **`core/standards/rules.md`** - Agent interaction rules and guidelines for this repository
  - When to check which AGENTS.md file
  - Kubernetes context usage guidelines
  - Secret naming patterns
  - App discovery patterns

### Code Standards
- **`core/standards/code.md`** - Code formatting and structure standards
  - YAML formatting (2-space indentation)
  - Kubernetes resource naming conventions
  - File naming patterns
  - NixOS module standards

## Workflows

### Common Operations
- **`core/workflows/deploy-new-app.md`** - Steps to deploy a new application
  - Create app directory structure
  - Add manifests and kustomization
  - Create encrypted secrets
  - Add to production overlay

- **`core/workflows/update-flux.md`** - Steps to update Flux components
  - Export current Flux components
  - Update gotk-components.yaml
  - Test reconciliation

- **`core/workflows/troubleshoot-flux.md`** - Common Flux troubleshooting
  - Check Flux status and logs
  - Validate manifests
  - Force reconciliation

## Domain Context

### Repository Architecture
- **`domain/server-config.md`** - Domain overview and architecture
  - Two-part architecture: NixOS hosts + FluxCD GitOps
  - Homelab cluster details
  - Technology stack

## Templates

### Application Templates
- **`core/templates/helm-app-template/`** - Template for Helm-based applications
  - Standard file structure
  - Example manifests
  - Secret references

## Usage

Agents should load relevant context files based on task type:

1. **Code tasks** → Load `core/standards/code.md`
2. **Agent interaction tasks** → Load `core/standards/rules.md`
3. **Workflow tasks** → Load appropriate workflow file
4. **Domain understanding** → Load `domain/server-config.md`

## Repository Structure Reference

- Base AGENTS.md: `/home/zshen/personal/server-config/AGENTS.md` (NixOS/host configuration)
- Flux AGENTS.md: `/home/zshen/personal/server-config/flux/AGENTS.md` (FluxCD/Kubernetes GitOps)

Last updated: $(date +%Y-%m-%d)