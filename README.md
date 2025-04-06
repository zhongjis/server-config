# Server Config

## hosts

| hostname  | ip             | usage    | where?                      |
| --------- | -------------- | -------- | --------------------------- |
| homelab-0 | 192.168.50.201 | k3s node | proxmox vm - thinkcentre-i7 |
| homelab-1 | 192.168.50.202 | k3s node | proxmox vm - thinkcentre-i5 |
| homelab-2 | 192.168.50.203 | k3s node | proxmox vm - thinkpad-t480  |
| vultr-lab | 45.77.189.121  | general  | vultr.com                   |

## commands

### initial deployment (nixos-anywhere)

#### linux

```nix
nix run nixpkgs#nixos-anywhere -- \
--flake .#homelab-0 \
--generate-hardware-config nixos-generate-config ./hosts/k3s/hardware-configuration-homelab-0.nix \
--extra-files /home/zshen/.config/sops/age \
nixos@192.168.50.192
```

#### darwin

```nix
nix run nixpkgs#nixos-anywhere -- \
--flake .#homelab-0 \
--generate-hardware-config nixos-generate-config ./hosts/k3s/hardware-configuration-homelab-0.nix \
--extra-files /Users/zshen/.config/sops/age \
nixos@192.168.50.192
```

### deployment/remote switch

#### colmena

```nix
colmena apply --on @homelab
```

#### `--target-host`

```nix
nixos-rebuild switch --flake .#homelab-1 \
  --target-host root@192.168.50.184
```
