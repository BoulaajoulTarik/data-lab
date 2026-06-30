# Operations

Day-to-day commands for running the lab locally and on the VPS.

## Local (WSL2)

| Command | What it does |
|---|---|
| `make infra-up` | Start shared infrastructure (Traefik, Portainer, whoami, monitoring, MinIO) |
| `make infra-down` | Stop shared infrastructure |
| `make infra-logs` | Tail shared infrastructure logs |
| `make new-project name=X` | Scaffold a new project from `projects/_template` |
| `make project-up name=X` | Start a project's dev stack |
| `make project-down name=X` | Stop a project's dev stack |
| `make logs name=X` | Tail a project's logs |
| `make webapp-up` | Start the apex portfolio webapp (tarik-lab.dev) |
| `scripts/check-prereqs.sh` | Verify local toolchain (docker, compose, make, git) |

!!! note
    The `web` external network must exist before the first `make infra-up`.
    Create it once: `docker network create web`

## VPS (production)

The VPS (`deploy@167.233.138.193`) is managed over SSH. The repo is private — directories
are synced via `rsync`, not `git clone`. There is no `make` on the VPS.

### Connect
```bash
ssh -i ~/.ssh/data-lab-deploy deploy@167.233.138.193
```

### Sync infrastructure
```bash
rsync -av --delete -e "ssh -i ~/.ssh/data-lab-deploy" \
  infrastructure/ deploy@167.233.138.193:~/data-lab/infrastructure/
```

### Rebuild docs site (after docs changes)
```bash
# On the VPS after syncing:
docker compose -f ~/data-lab/infrastructure/docker-compose.yml build docs
docker compose -f ~/data-lab/infrastructure/docker-compose.yml up -d docs
```

### Start / stop a stack (on VPS)
```bash
docker compose -f ~/data-lab/<stack>/docker-compose.yml up -d
docker compose -f ~/data-lab/<stack>/docker-compose.yml down
docker compose -f ~/data-lab/<stack>/docker-compose.yml logs -f
```

### Reset a Grafana admin password
```bash
docker exec $(docker ps -qf name=infrastructure-grafana) \
  grafana cli admin reset-admin-password <new-password>
```

## Deploy flow

`git push main` → build-push.yml (lint + build + GHCR) → deploy.yml (SSH pull + up).
Infrastructure changes (Traefik config, new services) are deployed manually via `rsync` + `docker compose up -d`.
