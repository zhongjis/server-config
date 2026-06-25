# Server Config

Homelab infrastructure repo for three Colmena-managed NixOS k3s nodes plus Flux-managed Kubernetes apps.

## Hosts

| Host | Role | IP | Notes |
|------|------|----|-------|
| `homelab-0` | k3s server/master | `192.168.50.104` | Labeled `n8n-node=true`. |
| `homelab-1` | k3s server/worker | `192.168.50.103` | Joins `homelab-0`. |
| `homelab-2` | k3s server/worker | `192.168.50.105` | Joins `homelab-0`. |

## Common commands

```bash
colmena build
colmena apply --on homelab-0
colmena apply --on homelab-1
colmena apply --on homelab-2
./flux/scripts/validate.sh
```

## Initial deployment with nixos-anywhere

Run from repo root. Replace `<host>` and `<ip>` with one row from the host table.

```bash
nix run nixpkgs#nixos-anywhere -- \
  --flake .#<host> \
  --generate-hardware-config nixos-generate-config ./hosts/k3s/hardware-configuration-<host>.nix \
  --extra-files /home/zshen/.config/sops/age \
  nixos@<ip>
```

On macOS, use `/Users/zshen/.config/sops/age` for `--extra-files`.
