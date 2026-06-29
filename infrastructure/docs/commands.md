# Operational commands

Every command needed to run the lab day to day, local and production (VPS). Quick reference first,
full explanation of each command below.

## Quick reference — local (WSL2)

| Command | Purpose |
|---|---|
| `make infra-up` | Start shared infrastructure (Traefik, Portainer, whoami) |
| `make infra-down` | Stop shared infrastructure |
| `make infra-logs` | Tail shared infrastructure logs |
| `make new-project name=X` | Scaffold a new project from `projects/_template` |
| `make project-up name=X` | Start a project's stack |
| `make project-down name=X` | Stop a project's stack |
| `make logs name=X` | Tail a project's logs |
| `make webapp-up` | Start the apex portfolio webapp (`tarik-lab.dev`) |
| `make webapp-down` | Stop the apex portfolio webapp |
| `make webapp-logs` | Tail the apex portfolio webapp logs |
| `scripts/check-prereqs.sh` | Verify the local toolchain (docker, compose, make, git) |

## Quick reference — VPS (production)

There is no `make` on the VPS — only `infrastructure/` and `projects/<name>/` are synced there, not
the rest of the repo (it's private, so the VPS can't `git clone` it). Every stack is driven with
plain `docker compose`, run over SSH.

| Command | Purpose |
|---|---|
| `ssh -i ~/.ssh/data-lab-deploy deploy@167.233.138.193` | Connect to the VPS |
| `rsync -avz -e "ssh -i ~/.ssh/data-lab-deploy" <local-dir>/ deploy@167.233.138.193:<remote-dir>/` | Sync a directory's contents onto the VPS |
| `docker compose -f <stack>/docker-compose.yml up -d` *(on the VPS)* | Start a stack in production |
| `docker compose -f <stack>/docker-compose.yml down` *(on the VPS)* | Stop a stack in production |
| `docker compose -f <stack>/docker-compose.yml logs -f` *(on the VPS)* | Tail a stack's logs in production |

---

## Local commands, in detail

### `make infra-up` / `make infra-down` / `make infra-logs`

Run `docker compose -f infrastructure/docker-compose.yml <up -d | down | logs -f>`. This is the
shared stack every other stack depends on: Traefik (reverse proxy + TLS termination), Portainer
(container admin UI), and `whoami` (routing-proof skeleton service). It must be up before any
project or the webapp can be reached through Traefik, because they only carry routing *labels* —
Traefik itself does the actual listening on ports 80/443.

`infra-down` does **not** remove the `web` network — it's declared `external: true` in the compose
file, so no compose file owns its lifecycle (see
[conventions/networking.md](conventions/networking.md)). If `web` doesn't exist yet (a fresh
machine), create it once with `docker network create web` before the first `infra-up`.

### `make new-project name=X`

Copies `projects/_template/` to `projects/X/`. Pure scaffolding — it doesn't start anything or touch
Docker. `name` is required; the Makefile errors out with a usage hint if it's omitted.

### `make project-up name=X` / `make project-down name=X` / `make logs name=X`

Run `docker compose -f projects/X/docker-compose.yml <up -d | down | logs -f>`. This is the generic
lifecycle for data projects (e.g. CP4's `demo`). It expects `projects/X/docker-compose.yml` to
already exist — either hand-written or produced by `new-project`. Like `infra-*`, `name` is
required.

### `make webapp-up` / `make webapp-down` / `make webapp-logs`

Run `docker compose -f projects/webapp/docker-compose.yml <up -d | down | logs -f>`. Deliberately
separate from `project-*` (different track — see `CLAUDE.md`'s apex exception note): this is the
personal portfolio page served at the bare domain `tarik-lab.dev`, not a `service.tarik-lab.dev`
data project. No `name=` argument — there's only one webapp stack.

### `scripts/check-prereqs.sh`

One-off toolchain check for a WSL2 machine: confirms `docker`, `docker compose` (v2 plugin), `make`,
and `git` are all installed and prints versions; exits non-zero with an `apt install` hint if
anything's missing. Not part of the routine start/stop cycle — run it once on a new machine, or
after troubleshooting a broken environment.

---

## VPS commands, in detail

The VPS (`167.233.138.193`, user `deploy`) only ever sees two directories synced from this repo:
`~/data-lab/infrastructure/` and `~/data-lab/projects/<name>/` (currently just `webapp`). The repo
itself is private and never cloned there — there's no git credential on the VPS at all. Every
deploy is: sync the relevant directory over, then run `docker compose` directly (no `make`, since
the Makefile isn't synced).

### Connect: `ssh -i ~/.ssh/data-lab-deploy deploy@167.233.138.193`

Uses the dedicated `data-lab-deploy` key (no passphrase). Root login and password auth are both
disabled on the VPS — this key plus the `deploy` user (NOPASSWD sudo) is the only way in.

### Sync a stack: `rsync -avz -e "ssh -i ~/.ssh/data-lab-deploy" <local-dir>/ deploy@167.233.138.193:<remote-dir>/`

`-a` preserves permissions/timestamps, `-z` compresses in transit. The trailing slash on both sides
matters — it syncs the *contents* of `<local-dir>` into `<remote-dir>`, not the directory itself
nested one level deeper. Examples actually used in this repo:

```bash
# infrastructure (Traefik, Portainer, whoami)
rsync -avz -e "ssh -i ~/.ssh/data-lab-deploy" infrastructure/ deploy@167.233.138.193:~/data-lab/infrastructure/

# apex webapp
rsync -avz -e "ssh -i ~/.ssh/data-lab-deploy" --exclude='.git' projects/webapp/ deploy@167.233.138.193:~/data-lab/projects/webapp/
```

If the remote directory doesn't exist yet (first deploy of a new stack), create it first:
`ssh -i ~/.ssh/data-lab-deploy deploy@167.233.138.193 "mkdir -p ~/data-lab/projects/<name>"`.

### Start / stop / tail on the VPS: `docker compose -f <stack>/docker-compose.yml <up -d | down | logs -f>`

Run this *on the VPS*, either over an interactive SSH session or piped through `ssh ... "cd
~/data-lab/<stack> && docker compose up -d"`. `up -d` is what actually triggers Traefik to pick up
the new container's labels and request a Let's Encrypt cert for its hostname (HTTP-01, port 80) —
that only happens once the container is running and joined to the `web` network on the VPS, which
already exists there from the infrastructure stack.

Secrets (e.g. `infrastructure/.env` with `TRAEFIK_DASHBOARD_AUTH`) are set directly on the VPS by
the human and are never part of the rsync payload from this repo.
