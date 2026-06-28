# CLAUDE.md — Data Lab

> This file is the project's memory. **Read it fully at the start of every session.** Update the
> State Tracker at the end of every task. Keep the Locked Decisions section authoritative — if a
> request contradicts it, stop and confirm with the human before proceeding.

## Mission

Build a self-hosted data-engineering lab that is (1) a learning environment, (2) a portfolio, and
(3) reachable on the public internet. **Completion comes first** — get a real project live, then add
optional capabilities. Favor finishing over scope.

## Locked decisions (source of truth)

- **Domain:** `tarik-lab.dev`
- **Subdomain scheme:** flat — `service.tarik-lab.dev` (e.g. `traefik.`, `portainer.`, `grafana.`, `demo.`, `<project>.`)
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
- **Stop at human-prep items.** Never create accounts, enter passwords/payment, handle SSH private keys, or change security settings. Draft scripts for the human to review and run; reference secrets by **name** only.
- If something contradicts Locked Decisions, **pause and ask** rather than improvising.

## Human-only boundary

These are the human's job; the agent advises but never performs them: account creation, payments,
domain/DNS registrar actions, pasting secret values, SSH private-key custody, VPS security settings
(firewall, sshd). Each checkpoint's **Human prep** block lists the ones for that stage.

## Where things are

- Checkpoint specs: `cp1-…` through `cp8-…` (in repo root or `docs/plan/`).
- Required path: CP1 → CP2 → CP3 (live, `v0.1`) → CP4 (CI/CD, `v0.2`).
- Optional: CP5 monitoring, CP6 MinIO, CP7 docs+diagrams, CP8 hardening.

## State tracker (living — keep current)

Status: ☐ not started · ◐ in progress · ☑ done

```
CP1 Local foundation ............... ☑
  1.1 WSL2 + Ubuntu ................ ☑ (human)
  1.2 .wslconfig memory cap ........ ☑ (applied + verified: 24GB/18 cores/8GB swap; host has 20 logical processors, 2 left for Windows)
  1.3 Docker Desktop (WSL2) ........ ☑ (human)
  1.4 Toolchain verify script ...... ☑
  1.5 GitHub repo + move into WSL2 . ☑ (human)
  1.6 Monorepo skeleton ............ ☑
  1.7 .gitignore ................... ☑
  1.8 Root Makefile (stubs) ........ ☑
  1.9 Place CLAUDE.md + README ..... ☑
  1.10 First commit (+tag cp1) ..... ☑
CP2 Local routing proof ............ ◐
  2.1 `web` network + conventions doc ☑
  2.2 Infrastructure compose scaffold ☑
  2.3 Traefik v3 (local, no ACME) ... ☑ (pinned v3.7.5 after v3.1/v3.5 broke vs this Docker Engine)
  2.4 Portainer CE .................. ☑ (pinned 2.39.4, routes via Traefik at portainer.localhost)
  2.5 `whoami` skeleton service ..... ☑ (pinned v1.11.0, routes via Traefik at whoami.localhost)
  2.6 `make infra-up`/`infra-down` .. ☑ (already wired in CP1; confirmed it picks up infrastructure/.env automatically)
  2.7 Verify routing locally ........ ☑ (whoami/portainer 200, traefik.localhost 401→200 w/ auth, unmatched host 404; *.localhost needs no /etc/hosts edit in modern browsers)
  2.8 Portainer admin password ...... ☐ (human)
  2.9 Commit + tag cp2 .............. ☐
CP3 LIVE on VPS (v0.1) ............. ☐
CP4 Real project + CI/CD (v0.2) .... ☐
CP5 Monitoring (optional) .......... ☐
CP6 MinIO + data project (opt) ..... ☐
CP7 Docs site + diagrams (opt) ..... ☐
CP8 Hardening & ops (opt) .......... ☐
```

## Session log (append a line per session)

- (e.g.) 2026-06-27 — created repo skeleton, CP1 through 1.8 done.
- 2026-06-28 — CP1 nearly complete: verified toolchain (1.4), wired git remote via SSH and
  renamed default branch to `main` (1.5), created monorepo skeleton (1.6), `.gitignore` (1.7),
  root `Makefile` (1.8), confirmed CLAUDE.md/README placement and refreshed README's stale
  "staging area" framing (1.9). Drafted `.wslconfig` (1.2) for human to apply — pending
  verification via `free -h`. Committed, pushed to `origin main`, tagged `cp1`.
- 2026-06-28 — Verified 1.2 (`.wslconfig`): `free -h` shows ~23Gi mem / 8Gi swap (matches 24GB/8GB
  cap); `nproc`=18 matches `processors=18`; user confirmed via Windows PowerShell that the host has
  20 logical processors total, so 2 are correctly left for Windows. CP1 is now fully ☑ complete.
- 2026-06-28 — CP2 underway: created the `web` network + conventions doc (2.1), scaffolded
  infrastructure/docker-compose.yml (2.2). Task 2.3 (Traefik) hit a real bug: `traefik:v3.1`/`v3.5`
  failed against this Docker Engine (Docker Desktop 4.79, API `MinAPIVersion=1.40`) with a cryptic
  empty 400 — diagnosed by proxying the docker.sock through a `socat -v` debug container, which
  showed Traefik's vendored Docker client hardcoding a bootstrap call to the old `/v1.24/version`
  endpoint. `traefik:v3.7.5` negotiates correctly; pinned that instead. User decided the project-wide
  fix is to always pin every image to its current latest stable tag (added to Conventions), not just
  for Docker-socket clients. Traefik dashboard now resolves at `traefik.localhost` behind basic auth.
