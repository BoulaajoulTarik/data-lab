# Data Lab — Build Plan (Completion-First)

This is the **live working repo** for the data-lab build, running in the WSL2 Linux filesystem at
`~/data-lab`.

> **Important:** keep working here, in the **WSL2 Linux filesystem at `~/data-lab`**, not on the
> Windows Desktop or under `/mnt/c`. Bind mounts and file-watching are slow/unreliable across that
> filesystem boundary.

## How this build is organized

The work is grouped into **checkpoints**, each ending in something that visibly works plus a Git
commit/tag (a safe resume point). The order follows a **walking skeleton**: prove the scary part —
the public deploy chain — *early* with a throwaway container, then make it real.

**Required path to a live portfolio (do these in order):**

| CP | File | You can show… |
|---|---|---|
| 1 | `cp1-local-foundation.md` | A clean monorepo + working toolchain |
| 2 | `cp2-local-routing-proof.md` | A container routed through Traefik locally |
| 3 | `cp3-live-on-vps.md` | **A public HTTPS URL that works** ← the milestone (`v0.1`) |
| 4 | `cp4-real-project-cicd.md` | `git push` → auto-deploy of your FastAPI app (`v0.2`) |

**Optional milestones (add later, zero rework — they're additive):**

| CP | File | Adds |
|---|---|---|
| 5 | `cp5-monitoring.md` | Grafana + Prometheus + Loki + cAdvisor |
| 6 | `cp6-minio-storage.md` | MinIO object storage + a data project that uses it |
| 7 | `cp7-docs-site.md` | MkDocs docs site + 5 architecture diagrams |
| 8 | `cp8-hardening-ops.md` | Backups, socket proxy, resource limits |

## The anchor: `CLAUDE.md`

`CLAUDE.md` holds the locked decisions, conventions, role definitions, and a **state tracker**. It is
read at the start of every Claude Code session and updated at the end of every task. It is what keeps
sequential agent sessions coherent. **Start here, keep it current.**

## Locked decisions (summary)

- **Domain:** `tarik-lab.dev` · **Subdomains:** flat (`grafana.tarik-lab.dev`, `<project>.tarik-lab.dev`)
- **Internet path:** VPS only (Hetzner). No Cloudflare. **TLS:** Let's Encrypt **HTTP-01**. **DNS:** wildcard A record at the registrar.
- **First project:** FastAPI · **Logs:** Loki Docker logging driver · **Registry:** GHCR (public images)
- **Network:** `web` (shared external) · **Repo root:** `~/data-lab` (WSL2) · **Tooling:** Claude Code in WSL2

## How to run the build

Open Claude Code in your WSL2 terminal at `~/data-lab`. Work **one task at a time, in order**. After
each task: verify its acceptance check, commit. After each checkpoint: tag. Hand the **human-prep**
items (accounts, payment, secrets, security settings) to yourself; hand everything else to the agent.
