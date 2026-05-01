# Uptime Kuma monitor inventory

Provisioning path: bootstrap these monitors manually in the Uptime Kuma UI from this inventory. Safe GitOps API seeding was not established, so these monitors are not fully GitOps-managed and this file stores no credentials.

Success rule: HTTP 2xx/3xx is up; auth redirects are acceptable; HTTP 5xx is down. HTTP 401/403 is down unless an app row explicitly says it is acceptable.

Search inputs used:
- Static Homepage entries: `flux/apps/base/homepage/ConfigMap.yaml` `services.yaml`.
- Production selection: `flux/apps/production-nondb/kustomization.yaml` resources.
- Homepage discovery search: `rg -n 'gethomepage\.dev/(enabled|name|href|description|group|icon|widget|pod-selector|weight)' flux/apps/base/{actualbudget,authentik/app,cloudflared,freshrss/app,home-assistant,homepage,karakeep,langfuse/app,litellm/app,n8n/app,redis,stirling-pdf}`.
- URL/host search: `rg -n 'host:|hosts:|hostname:|domain:|ingress:|route:|webhook\.n8n|zshen\.me|home' flux/apps/base/{actualbudget,authentik/app,cloudflared,freshrss/app,home-assistant,homepage,karakeep,langfuse/app,litellm/app,n8n/app,redis,stirling-pdf}`.

## Monitors

| App | URL | Expected status rule | Source file | Caveat |
| --- | --- | --- | --- | --- |
| ActualBudget | `https://budget.zshen.me` | 2xx/3xx up; auth redirect acceptable; 5xx down; 401/403 down | `flux/apps/base/actualbudget/HelmRelease.yaml` | Kubernetes/Homepage-discovered via `gethomepage.dev/enabled: "true"`. |
| Authentik | `https://authentik.zshen.me` | 2xx/3xx up; auth redirect acceptable; 5xx down; 401/403 down | `flux/apps/base/authentik/app/HelmRelease.yaml` | Kubernetes/Homepage-discovered via `gethomepage.dev/enabled: "true"`. |
| FreshRSS | `https://rss.zshen.me` | 2xx/3xx up; auth redirect acceptable; 5xx down; 401/403 down | `flux/apps/base/freshrss/app/HelmRelease.yaml` | Kubernetes/Homepage-discovered via `gethomepage.dev/enabled: "true"`. |
| Home Assistant | `https://assistant.zshen.me` | 2xx/3xx up; auth redirect acceptable; 5xx down; 401/403 down | `flux/apps/base/home-assistant/HelmRelease.yaml` | Kubernetes/Homepage-discovered via `gethomepage.dev/enabled: "true"`. |
| Karakeep | `https://karakeep.zshen.me` | 2xx/3xx up; auth redirect acceptable; 5xx down; 401/403 down | `flux/apps/base/karakeep/HelmRelease.yaml` | Kubernetes/Homepage-discovered via `gethomepage.dev/enabled: "true"`. |
| Langfuse | `https://langfuse.zshen.me` | 2xx/3xx up; auth redirect acceptable; 5xx down; 401/403 down | `flux/apps/base/langfuse/app/HelmRelease.yaml` | Kubernetes/Homepage-discovered via `gethomepage.dev/enabled: "true"`. |
| LiteLLM | `https://litellm.zshen.me` | 2xx/3xx up; auth redirect acceptable; 5xx down; 401/403 down | `flux/apps/base/litellm/app/HelmRelease.yaml` | Kubernetes/Homepage-discovered via `gethomepage.dev/enabled: "true"`. |
| n8n | `https://n8n.zshen.me` | 2xx/3xx up; auth redirect acceptable; 5xx down; 401/403 down | `flux/apps/base/n8n/app/HelmRelease.yaml` | Kubernetes/Homepage-discovered via `gethomepage.dev/enabled: "true"`. |
| Stirling PDF | `https://pdf.zshen.me` | 2xx/3xx up; auth redirect acceptable; 5xx down; 401/403 down | `flux/apps/base/stirling-pdf/HelmRelease.yaml` | Kubernetes/Homepage-discovered via `gethomepage.dev/enabled: "true"`. |
| Pi-hole | `http://pihole.home/admin` | 2xx/3xx up; auth redirect acceptable; 5xx down; 401/403 down | `flux/apps/base/homepage/ConfigMap.yaml` | Static Homepage entry; LAN `.home` reachability depends on Uptime Kuma resolver/network path. |
| Unifi Network | `http://network.home` | 2xx/3xx up; auth redirect acceptable; 5xx down; 401/403 down | `flux/apps/base/homepage/ConfigMap.yaml` | Static Homepage entry; LAN `.home` reachability depends on Uptime Kuma resolver/network path. |
| TrueNAS | `http://truenas.home` | 2xx/3xx up; auth redirect acceptable; 5xx down; 401/403 down | `flux/apps/base/homepage/ConfigMap.yaml` | Static Homepage entry; LAN `.home` reachability depends on Uptime Kuma resolver/network path. |
| Nextcloud | `http://truenas.home:30027` | 2xx/3xx up; auth redirect acceptable; 5xx down; 401/403 down | `flux/apps/base/homepage/ConfigMap.yaml` | Static Homepage entry; LAN `.home` reachability depends on Uptime Kuma resolver/network path. |
| Uptime Kuma | `https://status.zshen.me` | 2xx/3xx up; 5xx down; 401/403 down | `flux/apps/base/homepage/ConfigMap.yaml` | Static Homepage entry; monitor is useful after Uptime Kuma is bootstrapped and the status page exists/publishes. |

## Not monitored

| Target | Reason | Source file | Caveat |
| --- | --- | --- | --- |
| `https://webhook.n8n.zshen.me` | Not shown on Homepage by current static config or `gethomepage.dev/enabled: "true"` annotations; it appears only as the n8n webhook URL. | `flux/apps/base/n8n/app/HelmRelease.yaml` | Excluded from this Homepage-visible inventory. |
| Cloudflared | Selected by production-nondb but not shown on Homepage; no `gethomepage.dev/enabled: "true"` annotation found in selected base. | `flux/apps/base/cloudflared` | Infrastructure component, not a Homepage app entry. |
| Homepage | Selected by production-nondb but not shown as a Homepage service entry and has no `gethomepage.dev/enabled: "true"` annotation in its selected base. | `flux/apps/base/homepage` | This inventory covers apps displayed on Homepage, not Homepage itself. |
| Redis | Selected by production-nondb but not shown on Homepage; no `gethomepage.dev/enabled: "true"` annotation found in selected base. | `flux/apps/base/redis` | Backend dependency, not a Homepage app entry. |
