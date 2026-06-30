# CLAUDE.md — Data Lab

> This file is the project's memory. **Read it fully at the start of every session.** Update the
> State Tracker at the end of every task. Keep the Locked Decisions section authoritative — if a
> request contradicts it, stop and confirm with me before proceeding.

## Mission

Build a self-hosted data-engineering lab that is (1) a learning environment, (2) a portfolio, and
(3) reachable on the public internet. **Completion comes first** — get a real project live, then add
optional capabilities. Favor finishing over scope.

## Locked decisions (source of truth)

- **Domain:** `tarik-lab.dev`
- **Subdomain scheme:** flat — `service.tarik-lab.dev` (e.g. `traefik.`, `portainer.`, `grafana.`, `demo.`, `<project>.`)
- **Apex exception:** the bare domain `tarik-lab.dev` (no subdomain) serves the personal portfolio
  webapp (`projects/webapp/`, standalone task — see `docs/plan/apex-webapp-task.md`), not a flat-scheme
  service. Every other hostname still follows the flat subdomain scheme above.
- **Internet path:** **VPS only** (Hetzner Cloud). Cloudflare Tunnel is NOT used.
- **TLS:** Let's Encrypt via Traefik **HTTP-01** challenge (port 80). No DNS-01, no Cloudflare token.
- **DNS:** a **wildcard A record** (`*.tarik-lab.dev` and `tarik-lab.dev` → VPS IP) at the registrar.
  Per-hostname certs are issued automatically by Traefik; no wildcard cert needed.
- **First real project:** FastAPI (lightweight).
- **Container logs:** **Loki Docker logging driver** (not Promtail).
- **Image registry:** GHCR, images **public** (no pull token needed on the VPS).
- **Shared network:** `web` (external). Public services join `web`; project-internal services use a private `internal` network.
- **Repo root:** `~/data-lab` inside **WSL2** (Ubuntu 24.04). Never run from `/mnt/c`.
- **Tooling:** Claude Code in the WSL2 terminal.

## Conventions

- One shared external Docker network named `web`. Anything Traefik must reach is on `web`.
- Public service per stack carries Traefik labels routing `*.tarik-lab.dev` over the `websecure` entrypoint with the `le` certresolver. Internal services carry **no** Traefik labels.
- Secrets never enter Git. `.gitignore` ignores `.env` and `.env.*` but keeps `.env.example`.
- `.env.example` lists variable **names** only (empty values + comments). Real values live in local `.env` (Zone 1) or GitHub Actions secrets (Zone 2).
- Every Makefile recipe uses tabs. `name=X` targets guard against a missing/empty name.
- Docs live under `infrastructure/docs/` (markdown). Diagrams are Mermaid, committed as code.
- Pin every container image to its current latest stable release tag (never the floating `latest`
  tag) — check what's actually current when adding/touching a service, don't default to whatever
  version a tutorial/checkpoint doc happens to mention. Reason: `traefik:v3.1`/`v3.5` failed against
  this lab's Docker Engine (API `MinAPIVersion=1.40`) with a cryptic 400 because their vendored
  Docker client hardcoded a bootstrap call to the old `/v1.24/version` endpoint; `v3.7.5` fixed it.
  Stale pins can silently break against a host's current Docker Engine.

## Roles (the hats — one agent, switched posture per task)

Each task is tagged with the hat to wear:

- **[Builder]** — default (~80%). Writes Compose, Dockerfiles, Makefile targets, the FastAPI app, CI workflows, configs.
- **[Operator]** — VPS provisioning help, deploy debugging, DNS/TLS, 502s. Active mainly in CP3–CP4.
- **[Security review]** — a deliberate posture change *before each checkpoint commit*: re-read the work for leaked secrets, ungated admin UIs, exposed Docker socket, open ports. Use the checklist in each CP.
- **[Scribe]** — at the end of each task, update this file's State Tracker and any affected README/docs.

## Workflow rules

- **Sequential, single-agent, one task at a time.** Do not parallelize the required path.
- **Commit per task** (small, message describes the task). **Tag per checkpoint.**
- Before starting a task, confirm its **dependencies** are done in the State Tracker.
- After each task, run its **acceptance check** and only then mark it done and commit.
- **Stop at my-prep items.** Never create accounts, enter passwords/payment, handle SSH private keys, or change security settings. Draft scripts for me to review and run; reference secrets by **name** only.
- If something contradicts Locked Decisions, **pause and ask** rather than improvising.

## My boundary

These are my job; the agent advises but never performs them: account creation, payments,
domain/DNS registrar actions, pasting secret values, SSH private-key custody, VPS security settings
(firewall, sshd). Each checkpoint's **My prep** block lists the ones for that stage.

## Required path status

**COMPLETE as of 2026-06-30.** CP1 → CP2 → CP3 → CP4 are all ☑. The lab is a live,
self-updating portfolio: `git push main` → CI lint+build → GHCR → VPS deploy → HTTPS.
CP5–CP8 are optional enrichment — add anytime without rework.

## Where things are

- Checkpoint specs: `docs/plan/cp1-…` through `docs/plan/cp8-…`.
- Required path: CP1 → CP2 → CP3 (live, `v0.1`) → CP4 (CI/CD, `v0.2`).
- Optional: CP5 monitoring, CP6 MinIO, CP7 docs+diagrams, CP8 hardening.
- Standalone, out-of-scope task: `docs/plan/apex-webapp-task.md` — deploy a personal portfolio page at the
  apex `tarik-lab.dev`. Not part of CP1–CP8, does not touch the State Tracker, separate from CP4.

## State tracker (living — keep current)

Status: ☐ not started · ◐ in progress · ☑ done

```
CP1 Local foundation ............... ☑
  1.1 WSL2 + Ubuntu ................ ☑ (me)
  1.2 .wslconfig memory cap ........ ☑ (applied + verified: 24GB/18 cores/8GB swap; host has 20 logical processors, 2 left for Windows)
  1.3 Docker Desktop (WSL2) ........ ☑ (me)
  1.4 Toolchain verify script ...... ☑
  1.5 GitHub repo + move into WSL2 . ☑ (me)
  1.6 Monorepo skeleton ............ ☑
  1.7 .gitignore ................... ☑
  1.8 Root Makefile (stubs) ........ ☑
  1.9 Place CLAUDE.md + README ..... ☑
  1.10 First commit (+tag cp1) ..... ☑
CP2 Local routing proof ............ ☑
  2.1 `web` network + conventions doc ☑
  2.2 Infrastructure compose scaffold ☑
  2.3 Traefik v3 (local, no ACME) ... ☑ (pinned v3.7.5 after v3.1/v3.5 broke vs this Docker Engine)
  2.4 Portainer CE .................. ☑ (pinned 2.39.4, routes via Traefik at portainer.localhost)
  2.5 `whoami` skeleton service ..... ☑ (pinned v1.11.0, routes via Traefik at whoami.localhost)
  2.6 `make infra-up`/`infra-down` .. ☑ (already wired in CP1; confirmed it picks up infrastructure/.env automatically)
  2.7 Verify routing locally ........ ☑ (whoami/portainer 200, traefik.localhost 401→200 w/ auth, unmatched host 404; *.localhost needs no /etc/hosts edit in modern browsers)
  2.8 Portainer admin password ...... ☑ (me — done)
  2.9 Commit + tag cp2 .............. ☑
CP3 LIVE on VPS (v0.1) ............. ☑ (VPS 167.233.138.193, https://whoami.tarik-lab.dev live)
  3.1 Provision the VPS ............ ☑ (me — Hetzner regular-performance tier, Ubuntu 24.04.4 LTS)
  3.2 Harden the VPS ............... ☑ (drafted scripts/harden-vps.sh; I ran it — sudo user
      `deploy`, ufw 22/80/443 only, root login + password auth disabled, unattended-upgrades on;
      deploy given NOPASSWD sudo via /etc/sudoers.d/deploy-nopasswd to unblock Operator automation)
  3.3 Install Docker + Compose ..... ☑ (Docker 29.6.1, Compose plugin v5.2.0, via official apt repo)
  3.4 Infra repo onto VPS + `web` .. ☑ (repo is private — synced infrastructure/ via rsync instead of
      git clone; `web` bridge network created; I set TRAEFIK_DASHBOARD_AUTH in VPS .env directly)
  3.5 Traefik HTTP-01 + HTTPS ...... ☑ (certresolver `le`, web→websecure redirect on, acme.json in a
      named volume; routers switched to tarik-lab.dev hostnames over websecure)
  3.6 Wildcard DNS A record ........ ☑ (me — `*` and `@` → 167.233.138.193, confirmed resolving)
  3.7 Launch + verify HTTPS ........ ☑ (stack up; Let's Encrypt cert issued for whoami.tarik-lab.dev
      on first try; HTTP→HTTPS redirect confirmed)
  3.8 Security review .............. ☑ (only 22/80/443 reachable; dashboard/Portainer gated;
      acme.json 600 root:root; docker.sock mounts read-only; fixed infrastructure/.env perms
      664→600 on the VPS — was world-readable)
  3.9 Commit + tag cp3/v0.1 ........ ☑
CP4 Real project + CI/CD (v0.2) .... ☑ (demo.tarik-lab.dev live, auto-deploys on push)
  4.1 Project template _template ..... ☑
  4.2 make new-project + demo scaffold  ☑ (FastAPI /, /health; routes via Traefik locally)
  4.3 Demo Dockerfile ............... ☑ (slim Python, non-root, HEALTHCHECK)
  4.4 build-push.yml → GHCR ......... ☑ (latest + sha tags, GHA cache)
  4.5 GitHub Actions secrets ......... ☑ (me — VPS_SSH_KEY/HOST/USER set)
  4.6 deploy.yml → VPS .............. ☑ (workflow_run after build; SSH pull + up)
  4.7 CI quality gates .............. ☑ (ruff + docker compose config; gates build)
  4.8 First automated deploy ......... ☑ (push → GHCR → VPS; demo.tarik-lab.dev live)
  4.9 Security review ............... ☑ (no secrets in logs; admin UIs gated; VPS pulls public image)
  4.10 Commit + tag ................. ☑
CP5 Monitoring (optional) .......... ☑ (grafana.tarik-lab.dev live, provisioned datasources + dashboard, tagged cp5)
CP6 MinIO + data project (opt) ..... ☑ (minio.tarik-lab.dev + console.tarik-lab.dev live, ingest.tarik-lab.dev writes Parquet to demo-data, tagged cp6)
CP7 Docs site + diagrams (opt) ..... ☑ (docs.tarik-lab.dev live, MkDocs Material + nginx, 5 Mermaid diagrams, tagged cp7)
CP8 Hardening & ops (opt) .......... ☐
```

## Session log (append a line per session)

- (e.g.) 2026-06-27 — created repo skeleton, CP1 through 1.8 done.
- 2026-06-28 — CP1 nearly complete: verified toolchain (1.4), wired git remote via SSH and
  renamed default branch to `main` (1.5), created monorepo skeleton (1.6), `.gitignore` (1.7),
  root `Makefile` (1.8), confirmed CLAUDE.md/README placement and refreshed README's stale
  "staging area" framing (1.9). Drafted `.wslconfig` (1.2) for me to apply — pending
  verification via `free -h`. Committed, pushed to `origin main`, tagged `cp1`.
- 2026-06-28 — Verified 1.2 (`.wslconfig`): `free -h` shows ~23Gi mem / 8Gi swap (matches 24GB/8GB
  cap); `nproc`=18 matches `processors=18`; I confirmed via Windows PowerShell that the host has
  20 logical processors total, so 2 are correctly left for Windows. CP1 is now fully ☑ complete.
- 2026-06-28 — CP2 underway: created the `web` network + conventions doc (2.1), scaffolded
  infrastructure/docker-compose.yml (2.2). Task 2.3 (Traefik) hit a real bug: `traefik:v3.1`/`v3.5`
  failed against this Docker Engine (Docker Desktop 4.79, API `MinAPIVersion=1.40`) with a cryptic
  empty 400 — diagnosed by proxying the docker.sock through a `socat -v` debug container, which
  showed Traefik's vendored Docker client hardcoding a bootstrap call to the old `/v1.24/version`
  endpoint. `traefik:v3.7.5` negotiates correctly; pinned that instead. User decided the project-wide
  fix is to always pin every image to its current latest stable tag (added to Conventions), not just
  for Docker-socket clients. Traefik dashboard now resolves at `traefik.localhost` behind basic auth.
- 2026-06-28 — CP2 closed out: added Portainer CE (2.4, pinned 2.39.4) and the `traefik/whoami`
  skeleton (2.5, pinned v1.11.0), both routed through Traefik on `web`. Confirmed `make infra-up`/
  `infra-down` already pick up `infrastructure/.env` automatically (2.6). Verified routing locally —
  whoami/portainer return 200, `traefik.localhost` is gated by basic auth (401→200 with creds), an
  unmatched host falls through to 404 (2.7); modern browsers resolve `*.localhost` natively, no
  `/etc/hosts` edit needed. I set the Portainer admin password (2.8). Security review: no real
  secrets tracked, `.env` stays gitignored, both `docker.sock` mounts are read-only, only Traefik
  publishes host ports. CP2 fully ☑ complete, tagged `cp2`.
- 2026-06-28 — CP3 my-prep underway (3.1): Hetzner's cost-optimised tier (x86 older-gen / Arm64
  Ampere) is out of stock during an outage, in every location — only "regular performance" (x86 AMD,
  newer gen, shared vCPU) is available, at ~€20/mo instead of the ~€3.79/mo the spec assumed. I
  decided to proceed now at €20/mo rather than wait or change provider, with the intent to resize down
  to the cheap tier once Hetzner's stock recovers (resize = brief downtime, no data loss). Locked
  Decisions unchanged (still Hetzner Cloud); this is a temporary stock issue, not a provider change.
- 2026-06-29 — CP3 completed end to end. Generated a dedicated `data-lab-deploy` SSH key (no
  passphrase, by my choice) and attached it at VPS creation (3.1) — VPS public IP
  167.233.138.193, Ubuntu 24.04.4 LTS. Drafted `scripts/harden-vps.sh` for 3.2; I ran it. Hit a
  real lockout risk: the script's sudo user had no password, so once root SSH login was disabled
  there was briefly no way to gain root non-interactively — recovered via the still-open root
  session (`passwd deploy`), then by my choice switched `deploy` to NOPASSWD sudo via
  `/etc/sudoers.d/deploy-nopasswd` so the remaining Operator tasks could run unattended over SSH.
  Installed Docker 29.6.1 + Compose v5.2.0 from the official apt repo (3.3). Repo is private, so
  3.4 synced just `infrastructure/` via `rsync` instead of `git clone`; created the `web` network;
  I set `TRAEFIK_DASHBOARD_AUTH` directly in the VPS `.env` (hit a stale `nano` swap file from
  a dropped session on the first attempt, redone cleanly). Enabled Traefik's `le` certresolver,
  HTTP-01 on `web`, web→websecure redirect, and switched all routers to their `tarik-lab.dev`
  hostnames (3.5); I added the wildcard + apex `A` records, confirmed resolving (3.6). Launched
  the stack — Let's Encrypt issued a valid cert for `whoami.tarik-lab.dev` on the first attempt,
  verified HTTP→HTTPS redirect and cert issuer (3.7). Security review (3.8) found one real issue:
  `infrastructure/.env` was `664` (world-readable) on the VPS — tightened to `600`; everything else
  (ports, auth gating, `acme.json` perms, read-only docker.sock mounts) checked out clean.
  CP3 fully ☑ complete, tagged `cp3` and `v0.1`.
- 2026-06-30 — CP4 completed end to end. Tasks 4.1–4.4 (template, demo scaffold, Dockerfile,
  build-push.yml) were already committed from prior session. Today: drafted and validated
  deploy.yml (4.6) + quality gates in build-push.yml (4.7) + docker-compose.prod.yml; created
  ~/demo/.env on VPS (4.8 prep); confirmed VPS_SSH_KEY needed to be the existing data-lab-deploy
  key (new key generated on VPS had no authorized_keys entry — corrected). Pushed to main:
  build-push ran in 30s (ruff ✓, compose validate ✓, image pushed to GHCR); deploy ran in ~18s
  (SSH pull + up); https://demo.tarik-lab.dev/ returned {"service":"demo","version":"0.1.0"} on
  the first attempt. Security review (4.9): no secrets in logs, admin UIs gated, VPS pulls only
  the public GHCR image. CP4 fully ☑ complete. Required path CP1→CP4 is COMPLETE. Tagged cp4 + v0.2.
- 2026-06-30 — CP5 completed. Loki Docker logging driver (v3.7.2-amd64) installed on VPS; Loki
  (3.6.12) ships container logs. Prometheus (3.12.0) scrapes cadvisor (0.55.1) + Traefik metrics.
  Grafana (13.1.0) provisioned with both datasources and a Lab Overview dashboard (CPU, memory,
  logs panels). Grafana gated at grafana.tarik-lab.dev (anonymous access off, sign-up off).
  Hit: GF_SECURITY_ADMIN_PASSWORD with $ char caused auth issues — reset via grafana cli.
  CP5 fully ☑ complete, tagged cp5.
- 2026-07-01 — CP6 completed. MinIO (RELEASE.2025-09-07, last OSS release — repo archived Apr 2026)
  at minio.tarik-lab.dev (S3 API) + console.tarik-lab.dev. demo-data bucket + scoped access key
  (policy: read/write demo-data only). Ingest FastAPI project writes synthetic sensor Parquet on
  startup and exposes /ingest + /summary endpoints. CI/CD extended with parallel build+deploy jobs.
  ingest.tarik-lab.dev confirmed live with object in MinIO. CP6 fully ☑ complete, tagged cp6.
- 2026-07-01 — CP7 completed. MkDocs Material 9.6.20 multi-stage build (build → nginx 1.30.3-alpine)
  serving static site at docs.tarik-lab.dev. Five Mermaid diagrams covering ecosystem, infra
  internals, request routing, CI/CD, and project anatomy. Overview, Operations, Security pages
  written. No secrets in public docs. CP7 fully ☑ complete, tagged cp7.
