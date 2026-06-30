# Security Checklist

Reviewed as part of CP8 hardening. Run through this before each significant infrastructure change.

## Network perimeter

- [x] VPS firewall (ufw) allows only ports 22, 80, 443
- [x] All other ports blocked — Prometheus (9090), Loki (3100), MinIO S3 (9000) bound to `127.0.0.1` loopback
- [x] Internal services (socket-proxy) on the `internal` Docker network — no exposure to `web` or the host

## Auth-gated admin UIs

| Service | Gate | Status |
|---|---|---|
| Traefik dashboard | Traefik basicauth (`TRAEFIK_DASHBOARD_AUTH`) | ✅ |
| Portainer | Portainer own login | ✅ |
| Grafana | Grafana login (`GF_AUTH_ANONYMOUS_ENABLED=false`) | ✅ |
| MinIO console | MinIO login (`MINIO_ROOT_USER` / `MINIO_ROOT_PASSWORD`) | ✅ |

## Secrets

- [x] No secrets in Git — `.env` and `.env.*` are gitignored
- [x] `.env.example` files contain variable names only (empty values)
- [x] GitHub Actions secrets (`VPS_SSH_KEY`, `VPS_HOST`, `VPS_USER`) — not in logs
- [x] `acme.json` stored in a named volume, permissions `600 root:root`

## Docker socket

- [x] `socket-proxy` (`tecnativa/docker-socket-proxy:0.3.0`) filters the Docker API
- [x] Traefik uses the proxy via TCP — no direct `/var/run/docker.sock` mount
- [x] Portainer uses the proxy via `DOCKER_HOST=tcp://socket-proxy:2375` — no direct socket mount
- [x] `socket-proxy` lives on the `internal` network only (no route to `web`)
- [ ] cAdvisor retains `/var/run:/var/run:ro` for cgroup/containerd access — acceptable because
      it already runs `privileged: true` with broad host mounts for system metrics

## TLS

- [x] Let's Encrypt certs issued per-hostname via HTTP-01 challenge
- [x] HTTP → HTTPS redirect enforced at Traefik's `web` entrypoint
- [x] `websecure` entrypoint serves all public traffic

## Image hygiene

- [x] All images pinned to specific release tags (no `latest`)
- [x] Project images public on GHCR — no registry credentials needed on VPS
- [x] No `privileged: true` on public-facing services (only cAdvisor, internal metric collector)

## Resource limits (CP8)

- [x] CPU + memory limits applied to all infrastructure services
- [x] CPU + memory limits applied to project prod compose files (demo, ingest)
- [x] Prometheus retention capped at 15 days

## Backups (CP8)

- [x] `make backup` / `scripts/backup-volumes.sh` archives all stateful volumes
- [x] Restore procedure documented in `infrastructure/docs/operations/backups.md`
- [x] `backups/` gitignored

## SSH access

- [x] Root SSH login disabled on VPS (`PermitRootLogin no`)
- [x] Password authentication disabled (`PasswordAuthentication no`)
- [x] Key-only access via `deploy` user with `data-lab-deploy` key
