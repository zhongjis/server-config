# Server Config

## hosts

| hostname  | usage    | where?         |
| --------- | -------- | -------------- |
| homelab-0 | k3s node | thinkcentre-i7 |
| homelab-1 | k3s node | thinkcentre-i5 |

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

#### `--target-host`

```nix
nixos-rebuild switch --flake .#homelab-1 \
  --target-host root@192.168.50.184
```
