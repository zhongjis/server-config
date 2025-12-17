# homelab-1

```bash
kubectl drain homelab-1 --ignore-daemonsets --disable-eviction --delete-emptydir-data --force
colmena apply --on homelab-1 --reboot
kubectl uncordon homelab-1
```

# homelab-0

```bash
kubectl drain homelab-0 --ignore-daemonsets --disable-eviction --delete-emptydir-data --force
colmena apply --on homelab-0 --reboot
kubectl uncordon homelab-0
```
