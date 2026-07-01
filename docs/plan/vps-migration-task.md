# VPS Migration — CX22 cost-optimised replacement  [Standalone — outside CP1–CP8]

**Status:** complete as of 2026-07-01. New VPS `167.233.232.229` is live, old VPS deleted. See
CLAUDE.md session log for the full summary.

**Goal:** move the live stack (`infrastructure/`, `projects/ingest`, `projects/webapp`) from the
current Hetzner **regular-performance** VPS (`167.233.138.193`, 2 vCPU / 3.7 GB RAM / 75 GB disk,
~€20/mo) onto a new **CX23 cost-optimised** VPS (2 vCPU / 4 GB RAM / 40 GB disk, x86 Intel/AMD,
~€3.79–4.59/mo) — the plan originally wanted for CP3 but out of stock at the time (see CLAUDE.md
session log, 2026-06-28/29). The bought server's plan name shows as CX23 (Hetzner renamed the
cost-optimised x86 tier between CP3 and this task); specs are identical to what was scoped as CX22.

**Demo decommissioned, not migrated:** `projects/demo` (the CP4 required-path FastAPI walking
skeleton) is not moving to the new box — decided during this migration, its CI build/deploy jobs
and source were removed from the repo, and it goes away entirely when the old VPS is deleted (M.10).
`demo.tarik-lab.dev` will stop resolving to anything once that happens.

**Why a migration and not a resize:** Hetzner will not let a server rescale onto a plan with less
disk than it already has. The current box was provisioned directly at 75 GB, so the console will
never offer CX22 (40 GB) as a downgrade target for it — this is a platform rule, not a
configuration issue. Actual usage is only ~6 GB, so 40 GB is plenty of room on the new box; the
constraint is purely about the *old* server's disk allocation, not real capacity.

**Architecture note:** buy CX22 (x86), not CAX11 (Arm/Ampere) — same price class, but CI
(`build-push.yml`) builds amd64-only images. Arm would require multi-arch rebuilds of every image
before anything could run.

---

## My prep (boundary items — mine, not the agent's)

- [ ] **Buy the CX22** in the same Hetzner project/region as the current VPS, Ubuntu 24.04 LTS,
      attach the existing `data-lab-deploy` **public** key at creation. Note the new public IP.
      Do this now, while the cost-optimised tier is in stock — the old server keeps running
      untouched in the meantime, no rush on the cutover itself.
- [ ] **Run the hardening script** on the new box myself (reuses `scripts/harden-vps.sh` verbatim —
      no redraft needed, it's already generic).
- [ ] **Flip DNS** (`*.tarik-lab.dev` and `tarik-lab.dev` A records) to the new IP once the new box
      is verified working side-by-side with the old one.
- [ ] **Update `VPS_HOST`** in the GitHub Actions repo secrets to the new IP.
- [ ] **Delete the old server** (and its IPv4) only after the new one is confirmed live — don't
      power it off as a "just in case," delete it to stop billing once cutover is done.

---

## Tasks

### M.1 — Provision the new VPS  [Me]  [1×][PRE]
**How:** Hetzner console → create server → CX22 → Ubuntu 24.04 LTS → attach `data-lab-deploy`
public key → note the new IP.
**Acceptance:** `ssh -i ~/.ssh/data-lab-deploy deploy@<NEW_IP>`... will fail until M.2 creates that
user — for now, confirm `ssh -i ~/.ssh/data-lab-deploy root@<NEW_IP>` connects.

### M.2 — Harden the new VPS  [Me runs `scripts/harden-vps.sh`]  [1×]
**What/Why:** Same baseline as CP3 3.2 — sudo user, ufw 22/80/443 only, key-only SSH, unattended
upgrades. The script is already generic (no new drafting needed).
**Acceptance:** `deploy` user works over SSH with the existing key; root/password login disabled;
only 22/80/443 open.

### M.3 — Install Docker + Compose on the new VPS  [Operator]  [1×]
**Agent prompt:**
```
Over my authenticated SSH session to the NEW VPS, install Docker Engine + Compose v2 plugin via the
official Docker apt repo (not snap), add the deploy user to the docker group, verify with
`docker run --rm hello-world`. Report versions. Do not touch firewall or SSH settings.
```
**Acceptance:** `hello-world` runs on the new box.

### M.4 — Sync the repo + create `web` on the new VPS  [Operator]  [1×]
**Agent prompt:**
```
On the NEW VPS: create the external `web` network. Sync infrastructure/, projects/ingest, and
projects/webapp from the old VPS (or from the local repo) via rsync — same mechanism CP3 used (repo
is private, no git clone on the box). Skip projects/demo — it's being decommissioned, not migrated.
I will provide .env values for each (reference keys by name only). Do not start any stack yet.
```
**Acceptance:** repo present on the new VPS under the same path layout (`~/data-lab/...`); `web`
network exists.

### M.5 — Restore volumes from backup  [Operator]  [1×]
**What/Why:** Carry over MinIO objects, Grafana dashboards/users, Prometheus TSDB, Loki logs,
Portainer config. Let's Encrypt certs (`infrastructure_letsencrypt`) do **not** need restoring —
the new box gets fresh certs for its own boot, and old ones would be stale anyway.
**Agent prompt:**
```
Run scripts/backup-volumes.sh on the OLD VPS to get current archives. Copy them to the NEW VPS.
Following infrastructure/docs/operations/backups.md's restore procedure, restore
infrastructure_minio_data, infrastructure_grafana_data, infrastructure_prometheus_data, and
infrastructure_loki_data into freshly created volumes on the NEW VPS (skip
infrastructure_portainer_data if a clean admin setup is preferred; skip infrastructure_letsencrypt
entirely — new box issues its own certs). Do not start the stack until DNS cutover (M.7) is planned.
```
**Acceptance:** restored volumes exist on the new VPS with the expected data (spot-check MinIO
`demo-data` bucket, Grafana dashboard list).

### M.6 — Launch + verify on the new IP (pre-cutover)  [Operator]  [1×]
**What/Why:** Prove the new box works *before* DNS points at it, so there's no live-site downtime
risk. Traefik can't get real Let's Encrypt certs for the public hostnames until DNS points here, so
this step verifies over the bare IP / `curl -k` against the container, not `https://*.tarik-lab.dev`.
**Agent prompt:**
```
On the NEW VPS, bring up infrastructure and each project's compose stack. Confirm containers are
healthy (docker ps, health checks) and services respond internally (curl each service's port from
inside the `web` network, or curl -k the container directly). Do not expect valid public certs yet —
that depends on DNS (M.7). Report container health and any errors.
```
**Acceptance:** all services report healthy on the new box.

### M.7 — DNS cutover  [Me]  [1×]
**How:** at the registrar, change `A * <NEW_IP>` and `A @ <NEW_IP>` (wildcard + apex).
**Acceptance:** `dig whoami.tarik-lab.dev` (or any hostname) returns the new IP.

### M.8 — Verify live HTTPS on the new box  [Operator]  [1×]
**Agent prompt:**
```
After DNS cutover, watch Traefik on the NEW VPS request fresh Let's Encrypt certs for every
tarik-lab.dev hostname via HTTP-01. Verify from the public internet that each live URL
(whoami/portainer/traefik/grafana/minio/console/ingest/docs/tarik-lab.dev apex) loads with a
valid cert. Diagnose and fix any issuance failures (port 80 reachable, DNS propagated, acme.json
perms). Report results per hostname.
```
**Acceptance:** every previously-live hostname now serves from the new IP with a valid cert.

### M.9 — Update CI/CD target  [Me]  [1×]
**How:** GitHub repo → Settings → Secrets → update `VPS_HOST` to the new IP.
**Acceptance:** next `git push main` deploys successfully to the new box (watch the Actions run).

### M.10 — Decommission the old VPS  [Me]  [1×]
**What/Why:** Stop paying for two servers. Only after M.8 and M.9 are both confirmed.
**How:** Hetzner console → delete the old server **and** its IPv4 (not just power off).
**Acceptance:** old server no longer listed; billing reflects one server going forward.

### M.11 — Security review  [Security review]  [1×]
**Agent prompt:**
```
Security review of the new live VPS: confirm only 22/80/443 open; Traefik dashboard + Portainer +
Grafana still auth-gated; no .env or secrets world-readable; acme.json is 600; docker socket proxy
(from CP8) still in place, not a raw socket mount. List findings, fix anything regressed from the
old box's posture, re-verify.
```
**Acceptance:** security posture matches or exceeds the old box (CP3 3.8, CP8 checklist).

### M.12 — Commit + update tracker  [Scribe → commit]  [1×]
**Agent prompt:**
```
Commit "chore: migrate VPS to cost-optimised CX22", update CLAUDE.md session log with the new IP and
migration summary, push. This is a standalone task like apex-webapp-task.md — no CP State Tracker
row, no new tag required unless requested.
```
**Acceptance:** CLAUDE.md session log reflects the new IP; repo pushed.

---

## Restrictions

- **Do not touch DNS or delete the old server** until M.6/M.8 confirm the new box works — keep both
  running in parallel until cutover is verified.
- **Do not skip the pre-cutover verification (M.6)** — diagnosing a broken new box is much easier
  before it's the box the public is hitting.
- **Reference secrets/`.env` values by name only**, same as every other VPS task in this repo.

## Checkpoint exit
Same live URLs, same functionality, on a ~€16–20/mo cheaper server. Old VPS deleted, CI/CD retargeted,
CLAUDE.md session log updated with the new IP.
