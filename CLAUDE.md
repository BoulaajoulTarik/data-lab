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
CP1 Local foundation ............... ◐
  1.1 WSL2 + Ubuntu ................ ☑ (human)
  1.2 .wslconfig memory cap ........ ◐ (drafted; human to apply + verify)
  1.3 Docker Desktop (WSL2) ........ ☑ (human)
  1.4 Toolchain verify script ...... ☑
  1.5 GitHub repo + move into WSL2 . ☑ (human)
  1.6 Monorepo skeleton ............ ☑
  1.7 .gitignore ................... ☑
  1.8 Root Makefile (stubs) ........ ☑
  1.9 Place CLAUDE.md + README ..... ☑
  1.10 First commit (+tag cp1) ..... ☑
CP2 Local routing proof ............ ☐
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
