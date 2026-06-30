# Security

## Network perimeter

Only three ports are open on the VPS firewall (ufw):

| Port | Purpose |
|---|---|
| 22 | SSH (key-only, root disabled) |
| 80 | HTTP — used only for Let's Encrypt HTTP-01 challenge, then redirects to HTTPS |
| 443 | HTTPS — all public traffic via Traefik |

All other ports are blocked. Internal services (Prometheus, cAdvisor, Loki, Prometheus) are bound
to `127.0.0.1` loopback on the VPS and are not reachable from the internet.

## Auth-gated admin UIs

| Service | Protection |
|---|---|
| Traefik dashboard | Traefik basicauth middleware (`TRAEFIK_DASHBOARD_AUTH`) |
| Portainer | Portainer own login (set on first use) |
| Grafana | Grafana login (`GF_AUTH_ANONYMOUS_ENABLED=false`) |
| MinIO console | MinIO login (`MINIO_ROOT_USER` / `MINIO_ROOT_PASSWORD`) |

## Secrets model (three zones)

```
Zone 1 — Local
  infrastructure/.env     (gitignored, set manually)
  projects/<name>/.env    (gitignored, set manually)

Zone 2 — GitHub Actions
  VPS_SSH_KEY, VPS_HOST, VPS_USER
  (repo secrets, used only by CI/CD workflows)

Zone 3 — VPS
  ~/data-lab/infrastructure/.env     (set directly on VPS, never synced from repo)
  ~/ingest/.env, ~/demo/.env         (set directly on VPS)
```

`.env.example` files commit only variable **names** (empty values). Real values never enter git.

## Docker socket

Traefik and Portainer mount `/var/run/docker.sock:ro` (read-only). A full socket proxy
(CP8) is planned to further restrict which Docker API endpoints each consumer can reach.

## TLS

Let's Encrypt certificates are issued per-hostname via HTTP-01 challenge. `acme.json` is
stored in a named Docker volume (`letsencrypt`), permissions `600 root:root`.

## Image sourcing

All images are pinned to specific release tags (no `latest`). Project images are public
on GHCR — no registry credentials needed on the VPS.
