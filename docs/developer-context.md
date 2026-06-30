# Data Lab — Developer Context

> Hand this document to an agent implementing a data project in this repo. It covers every
> convention, tool, and path needed to build and deploy a new project without reading all the
> source code.

---

## Repo layout

```
data-lab/
├── projects/
│   ├── _template/          # copy this for every new project
│   ├── demo/               # reference implementation — read this first
│   └── webapp/             # apex portfolio page (separate track, ignore)
├── infrastructure/
│   ├── docker-compose.yml  # Traefik + Portainer + whoami
│   ├── traefik/            # Traefik static config
│   └── docs/               # operational commands, networking conventions
├── .github/workflows/
│   ├── build-push.yml      # CI: lint → build → push to GHCR
│   └── deploy.yml          # CD: SSH into VPS → pull → restart
├── docs/
│   └── plan/               # CP1–CP8 checkpoint specs
├── scripts/
└── Makefile                # root-level shortcuts
```

The reference implementation to read before building anything new: **`projects/demo/`**.

---

## Creating a new project

```bash
make new-project name=<project-name>
```

This copies `projects/_template/` to `projects/<name>/`, substituting `PROJECT_NAME`. Then
edit the generated files:

1. `docker-compose.yml` — add services, adjust ports, add backing services on `internal`
2. `.env.example` — add env var names (no values)
3. `Makefile` — already wired; no changes needed for basic up/down/logs

Never edit `projects/_template/` unless updating the convention itself.

---

## Network rules (mandatory)

Two networks; every service goes on exactly one or both:

| Network | Name | Who joins | Traefik labels |
|---|---|---|---|
| Public | `web` (external) | The one service Traefik must reach | Yes |
| Private | `internal` (bridge, per-project) | Databases, caches, workers | No |

**Rule**: if a service has Traefik labels, it is on `web`. If it has no Traefik labels, it is
on `internal` only. Never put a database on `web`.

Compose snippet:

```yaml
networks:
  web:
    external: true
  internal:
    driver: bridge

services:
  app:
    networks: [web]
    labels:
      - "traefik.enable=true"
      # ...

  db:
    networks: [internal]
    # no labels
```

---

## Traefik label convention

Every public service uses these four labels (substitute `<name>` with the project name):

```yaml
labels:
  - "traefik.enable=true"
  - "traefik.http.routers.<name>.rule=Host(`<name>.tarik-lab.dev`)"
  - "traefik.http.routers.<name>.entrypoints=websecure"
  - "traefik.http.routers.<name>.tls.certresolver=le"
  - "traefik.http.services.<name>.loadbalancer.server.port=<container-port>"
```

TLS cert is issued automatically by Let's Encrypt (HTTP-01) on first container start. No DNS
work needed — the wildcard A record `*.tarik-lab.dev → 167.233.138.193` already exists.

---

## Compose file patterns

**Local dev** (`docker-compose.yml`): uses `build: .`, reads from `.env`, routes via
`<name>.localhost` (or leave as `tarik-lab.dev` — both work locally for testing labels).

**VPS production** (`docker-compose.prod.yml`): uses `image: ${DEMO_IMAGE}` (injected by the
deploy workflow), same Traefik labels with `tarik-lab.dev` hostnames, `env_file: .env`.

See `projects/demo/docker-compose.yml` and `projects/demo/docker-compose.prod.yml` for the
exact pattern to copy.

---

## CI/CD pipeline

### build-push.yml

Triggers on push to `main` when files under `projects/demo/**` or the workflow itself change.
**Adjust the `paths:` filter** to include your project directory.

Steps (in order, all must pass):
1. `ruff check projects/<name>/app` — lint gate; fails the build on any error
2. `docker compose config` on all compose files — validates YAML + env var substitution
3. `docker/build-push-action` → pushes to GHCR as:
   - `ghcr.io/boulaajoultarik/data-lab-<name>:latest`
   - `ghcr.io/boulaajoultarik/data-lab-<name>:<git-sha>`

Image names are always lowercase. The workflow lowercases `github.repository_owner`
automatically.

### deploy.yml

Triggers automatically when `build-push` completes successfully on `main`.

Steps:
1. Computes `DEMO_IMAGE=ghcr.io/boulaajoultarik/data-lab-<name>:latest`
2. Sets up SSH using `VPS_SSH_KEY` secret
3. `scp` the `docker-compose.prod.yml` to `~/<name>/docker-compose.yml` on VPS
4. SSH: `docker compose pull --quiet && docker compose up -d`

**For a new project**, copy `deploy.yml`, replace references to `demo` with `<name>`, and
update the VPS target directory (`~/demo/` → `~/<name>/`).

### GitHub Actions secrets (already set)

| Secret | Value |
|---|---|
| `VPS_SSH_KEY` | Private key of `data-lab-deploy` (ED25519, no passphrase) |
| `VPS_HOST` | `167.233.138.193` |
| `VPS_USER` | `deploy` |
| `GITHUB_TOKEN` | Built-in; used for GHCR push (packages: write) |

No new secrets needed for additional projects unless they require external API keys.

---

## VPS layout

```
/home/deploy/
├── demo/
│   ├── docker-compose.yml   # synced from projects/demo/docker-compose.prod.yml by deploy.yml
│   └── .env                 # app runtime vars — set once by hand, never overwritten by CI
├── data-lab/
│   └── infrastructure/      # synced via rsync (not git — repo is private)
│       ├── docker-compose.yml
│       └── .env             # TRAEFIK_DASHBOARD_AUTH — set by hand, 600 perms
```

**SSH access**: `ssh -i ~/.ssh/data-lab-deploy deploy@167.233.138.193`
User `deploy` has NOPASSWD sudo. Root login is disabled.

For a new project, the VPS deploy directory (`~/<name>/`) and its `.env` must be created once
before the first CI deploy:

```bash
ssh -i ~/.ssh/data-lab-deploy deploy@167.233.138.193 \
  'mkdir -p ~/<name> && printf "APP_VERSION=0.1.0\n" > ~/<name>/.env && chmod 600 ~/<name>/.env'
```

---

## GHCR image registry

Registry: `ghcr.io`
Owner (lowercase): `boulaajoultarik`
Image naming: `ghcr.io/boulaajoultarik/data-lab-<project-name>:latest`

All images are **public** — the VPS pulls without credentials. Set a new package to public in
GitHub → Profile → Packages → `<image>` → Package settings → Change visibility, after the
first push.

---

## Dockerfile conventions

Follow `projects/demo/Dockerfile` exactly:

- Base: `python:3.14.6-slim` (or current slim; pin to the exact tag)
- `WORKDIR /app`
- Copy and install `requirements.txt` before copying source (layer cache)
- Create a non-root user with no home dir and no shell; `chown` the workdir; `USER appuser`
- `HEALTHCHECK` hitting `/health` via `urllib.request` (no curl/wget dependency)
- `CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]`

---

## Local dev commands

```bash
make new-project name=<name>    # scaffold
make project-up name=<name>     # docker compose up -d
make project-down name=<name>   # docker compose down
make logs name=<name>           # docker compose logs -f
make infra-up                   # start Traefik + Portainer (needed for routing)
```

Infrastructure must be up (`make infra-up`) for Traefik to route to your project locally.

---

## Code quality gates

The build fails if either of these fail:

1. **Ruff** — default rules, no config file. Run locally: `ruff check projects/<name>/app`
2. **Compose validation** — `docker compose config --quiet` on every compose file. Uses
   `.env.example` copied to `.env` for CI (env vars must be declared in `.env.example`).

Keep `projects/<name>/.env.example` up to date with every env var the compose files reference.

---

## Git conventions

- Branch: `main` is the only long-lived branch. Force-push is blocked.
- History: linear only (no merge commits). Rebase before pushing if needed.
- Commit style: `feat: <description> (<task-id>)` — e.g. `feat: add ingest pipeline (5.2)`
- One commit per task; tag per checkpoint: `git tag cp5 && git push --tags`
- Secret scanning push protection is on — a push containing a detected secret pattern is
  rejected before it reaches GitHub.

---

## FastAPI app conventions

Follow `projects/demo/app/main.py`:

```python
import os
from fastapi import FastAPI

VERSION = os.getenv("APP_VERSION", "0.1.0")
app = FastAPI()

@app.get("/")
def root() -> dict:
    return {"service": "<name>", "version": VERSION}

@app.get("/health")
def health() -> dict:
    return {"status": "ok"}
```

- Read all config from environment variables (never hardcode)
- Always expose `/health` — the Dockerfile HEALTHCHECK and Traefik health probes use it
- `requirements.txt` pins exact versions: `fastapi==X.Y.Z`, `uvicorn[standard]==X.Y.Z`
