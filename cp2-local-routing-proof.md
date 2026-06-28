# CP2 — Local Routing Proof  [Required]

**Goal:** Prove the routing model locally: Traefik auto-discovers a container on the shared `web`
network and routes to it, with Portainer for visibility. Uses a throwaway `traefik/whoami` container
as the stand-in (the walking skeleton's local half).

**Walking-skeleton role:** make routing work locally with a trivial container *before* taking it
public or building the real app.

**Depends on:** CP1.

**Checkpoint done when:** `whoami.localhost` (or a hosts entry) routes through Traefik to the whoami
container, and Portainer loads. → commit, tag `cp2`.

---

## Human prep
- [ ] None external. One local step at the end: set a **Portainer admin password** on first login (2.8).
- [ ] When the agent generates a Traefik dashboard basic-auth hash, you'll paste the **real** password into local `.env` (the agent uses a placeholder).

---

## Tasks

### 2.1 — Create the `web` network + convention doc  [Builder]  [1×]
**What/Why:** *The critical foundation.* Traefik can only route to containers sharing its network.
**Agent prompt:**
```
Create the shared external Docker network `web` (idempotent). Write
infrastructure/docs/conventions/networking.md (<30 lines): `web` is the shared external proxy network
Traefik and all public services join; project-internal services use a private `internal` network;
how to reference `web` as external: true in compose. Confirm with `docker network ls`.
```
**Acceptance:** `docker network ls` lists `web`; doc exists. **Effort:** 🟡

### 2.2 — Infrastructure compose scaffold  [Builder]  [1×]
**Agent prompt:**
```
Create infrastructure/docker-compose.yml: declare network `web` as external: true; declare named
volumes for portainer (and placeholders, commented, for minio/grafana/prometheus/loki for later).
Add section comments per service group. No services yet beyond what later tasks add. Validate with
`docker compose -f infrastructure/docker-compose.yml config`.
```
**Acceptance:** `docker compose config` succeeds. **Effort:** 🟡

### 2.3 — Traefik v3 (local, no ACME yet)  [Builder]  [1×]
**What/Why:** The router. ACME/HTTP-01 is added in CP3 (VPS); locally we route plain HTTP.
**Agent prompt:**
```
Add Traefik v3 to infrastructure/docker-compose.yml + infrastructure/traefik/traefik.yml.
- entrypoints: web(:80), websecure(:443). For LOCAL, don't force https redirect yet (add it,
  commented, to enable in CP3).
- Docker provider, exposedByDefault: false, watching the `web` network.
- Dashboard enabled, routed at traefik.localhost, behind a basicauth middleware. Generate a
  PLACEHOLDER htpasswd hash and tell me how to replace it via .env; add the key to
  infrastructure/.env.example. Do not invent real credentials.
- Mount /var/run/docker.sock read-only (note: socket proxy comes in CP8).
- Add a commented ACME/HTTP-01 certresolver block labeled "enable in CP3 (VPS)".
Attach Traefik to `web`. Validate config; start only Traefik; confirm the dashboard route resolves.
```
**Acceptance:** Traefik starts; `traefik.localhost` shows the dashboard (after a hosts entry / via
`.localhost`). **Effort:** 🟠

### 2.4 — Portainer CE  [Builder]  [1×]
**Agent prompt:**
```
Add Portainer CE to infrastructure/docker-compose.yml: attach to `web`, persist to a named volume,
mount the Docker socket read-only, Traefik labels routing portainer.localhost (websecure once CP3
lands; web for now). Do not set an admin password in config. Add a reminder to set a strong admin
password on first login. Validate config.
```
**Acceptance:** Portainer reachable locally via Traefik. **Effort:** 🟡

### 2.5 — `traefik/whoami` skeleton service  [Builder]  [1×]
**What/Why:** A tiny off-the-shelf container that echoes request info — perfect routing stand-in; no
build needed.
**Agent prompt:**
```
Add a `whoami` service (image traefik/whoami) to infrastructure/docker-compose.yml, attached to
`web`, with Traefik labels routing whoami.localhost (entrypoint web for now; comment the websecure+le
version for CP3). Validate config.
```
**Acceptance:** service defined; config valid. **Effort:** 🟢

### 2.6 — Wire `make infra-up` / `infra-down`  [Builder]  [1×]
**Agent prompt:**
```
Update the Makefile so infra-up = `docker compose -f infrastructure/docker-compose.yml up -d`,
infra-down = the matching down, infra-logs tails all infra logs. Run `make infra-up`; list containers.
```
**Acceptance:** `make infra-up` starts Traefik, Portainer, whoami. **Effort:** 🟢

### 2.7 — Verify routing locally  [Operator]  [1×]
**Agent prompt:**
```
Bring up the infra stack. Verify Traefik routes to whoami, Portainer, and its own dashboard. Since
DNS isn't public, use *.localhost or /etc/hosts and report the exact URLs to test. For any 502/404,
diagnose (not on `web`, wrong label, wrong port) and fix. Summarize the working URL list.
```
**Acceptance:** whoami.localhost returns the whoami page through Traefik; Portainer + dashboard load.
**Effort:** 🟠

### 2.8 — Set Portainer admin password  [Human]  [1×]
**What/Why:** Avoid a default-cred admin surface even locally. **How:** open Portainer, set a strong
password, store in your password manager.
**Acceptance:** Portainer requires your password.

### 2.9 — Commit + tag  [Security review → commit]  [1×]
**Agent prompt:**
```
Security review: confirm no real secrets committed (only placeholder htpasswd + .env.example keys),
.env not tracked. Commit "feat: local infra + Traefik routing proof (whoami)", tag cp2, push. Update
CLAUDE.md State Tracker (CP2 ☑) and add a session-log line.
```
**Acceptance:** tag `cp2`; tracker updated. **Effort:** 🟢

---

## Checkpoint exit
A container is provably routed through Traefik locally, Portainer is up and secured, and the routing
conventions are documented. Tag: `cp2`. Next: take this exact pattern public on the VPS.
