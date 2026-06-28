# CP8 — Hardening & Operations  [Optional milestone]

**Goal:** Turn a working lab into a maintainable, defensible one: backups, a safer Docker socket
posture, and resource limits so no project can starve the platform.

**Depends on:** a working stack (CP3/CP4+). Do these once the lab is stable and you want it durable.

**Done when:** backups run, the socket is proxied, and heavy services have limits. → tag `cp8`.

---

## Human prep
- [ ] None required. Optionally decide where backup archives should live (default: on the VPS under a gitignored `backups/`; consider copying off-box manually for real safety).

---

## Tasks

### 8.1 — Volume backups  [Builder]  [1×]
**What/Why:** *Concern G.* All persistence (MinIO, Grafana, Prometheus, Loki, project DBs) is in
volumes with no backup.
**Agent prompt:**
```
Create scripts/backup-volumes.sh that archives the stateful named volumes (minio, grafana,
prometheus, loki, any project db) into timestamped tarballs under a gitignored backups/, using a
temporary helper container to read each volume. Add `make backup`. Write a restore procedure in
infrastructure/docs/operations/backups.md. Test on one volume; confirm the archive is non-empty.
```
**Acceptance:** `make backup` produces archives; restore documented. **Effort:** 🟡

### 8.2 — Docker socket proxy  [Builder]  [1×]
**What/Why:** Mounting the raw `docker.sock` is root-equivalent. A proxy exposes only needed endpoints.
**Agent prompt:**
```
Introduce a docker-socket-proxy service. Configure least-privilege endpoints per consumer (Traefik:
containers/networks read; cAdvisor: stats read; Portainer: documented broader set). Repoint those
services at the proxy over the internal network and remove their direct /var/run/docker.sock mounts
where possible. Document the permission rationale. Verify Traefik still discovers routes and Portainer
still works after the change.
```
**Acceptance:** services function via the proxy; direct socket mounts removed where feasible. **Effort:** 🟠

### 8.3 — Resource limits on heavy services  [Builder]  [↻]
**What/Why:** *Concern H.* Keep any one project within bounds under the WSL2 cap and on the modest VPS.
**Agent prompt:**
```
Add CPU/memory limits to resource-heavy services across projects/* (and Prometheus/Loki retention if
needed), informed by what Grafana shows for typical usage, leaving headroom for the always-on stack.
Document chosen values + reasoning. Confirm services still start and run within limits.
```
**Acceptance:** limits applied; services stable. **Effort:** 🟡

### 8.4 — Final security pass + commit  [Security review → commit]  [1×]
**Agent prompt:**
```
Full security review: ports (22/80/443 only), admin UIs gated, no exposed secrets, acme.json 600,
socket proxied, images public-by-intent only. Produce a short security checklist doc under
infrastructure/docs/security/. Commit "chore: hardening (backups, socket proxy, limits)", tag cp8,
push. Update CLAUDE.md tracker + session log.
```
**Acceptance:** checklist passes; tag `cp8`. **Effort:** 🟢

---

## Checkpoint exit
The lab is backed up, the socket is contained, and resources are bounded. Tag: `cp8`.

---

## You're done
At this point: always-on infra, a self-updating FastAPI portfolio live over HTTPS at
`tarik-lab.dev`, and (as you added them) monitoring, object storage with a data project, a docs site
with architecture diagrams, and hardening — a working platform and a portfolio piece in one, every
step resumable from its checkpoint tag.
