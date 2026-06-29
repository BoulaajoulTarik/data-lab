# data-lab

A self-hosted data-engineering lab, built and operated as a public portfolio: real infrastructure,
a real VPS, real HTTPS, real CI/CD — not a tutorial sandbox.

**Live:** https://whoami.tarik-lab.dev · https://tarik-lab.dev (portfolio)

## What this is

Everything here runs on a single Hetzner VPS behind Traefik, with TLS issued automatically via
Let's Encrypt and every public service on one shared Docker network. The build follows a
"walking skeleton" approach: prove the riskiest part first (getting a container onto the public
internet over real HTTPS) with a throwaway service, then swap in real projects on the same rails.

Built collaboratively with [Claude Code](https://claude.com/claude-code) as a hands-on exercise in
agent-assisted infrastructure work — the agent drafts and operates, I own accounts, payments,
secrets, and security-sensitive settings. See `docs/plan/` for the checkpoint-by-checkpoint build
plan this lab was built from.

- **Reverse proxy / TLS:** Traefik v3, Let's Encrypt HTTP-01, per-host certs
- **Hosting:** Hetzner Cloud VPS, hardened (key-only SSH, ufw, unattended-upgrades)
- **Registry:** GHCR (public images)
- **DNS:** wildcard record, flat subdomain scheme (`service.tarik-lab.dev`)
- **CI/CD:** GitHub Actions → build → push to GHCR → deploy to VPS

## Layout

| Path | What's there |
|---|---|
| `infrastructure/` | Shared stack — Traefik, Portainer, the `web` network conventions |
| `projects/` | Individual services, each on its own subdomain (`_template` to copy from) |
| `scripts/` | One-off operational scripts (VPS hardening, prereq checks) |
| `docs/plan/` | The checkpoint-by-checkpoint build plan this lab was built from |
| `CLAUDE.md` | Locked decisions, conventions, and current build status — the project's source of truth |

## Current status

See `CLAUDE.md`'s State Tracker for up-to-date checkpoint status.
