# Data Lab — Brainstorming Context

> Hand this document to an agent helping brainstorm data project ideas. It describes what is
> already running, what is trivially addable, and what the constraints are, so suggestions stay
> grounded in what is actually achievable on this stack.

---

## Goal

Build data-engineering projects that are (1) good learning material, (2) portfolio-visible, and
(3) live on the public internet. Completion matters more than scope — a small thing that is
genuinely live beats a large thing that is half-built.

---

## What is live right now

| Service | URL | Role |
|---|---|---|
| FastAPI demo app | `https://demo.tarik-lab.dev` | Proof-of-concept project; auto-deploys on `git push` |
| Portfolio webapp | `https://tarik-lab.dev` | Personal portfolio page (nginx, standalone) |
| Traefik dashboard | `https://traefik.tarik-lab.dev` | Reverse proxy admin (basic-auth gated) |
| Portainer | `https://portainer.tarik-lab.dev` | Container management UI (password gated) |
| whoami diagnostic | `https://whoami.tarik-lab.dev` | Routing sanity check |

Every public hostname uses a Let's Encrypt TLS cert issued automatically. Adding a new service at
`https://<anything>.tarik-lab.dev` requires zero DNS or certificate work — just Traefik labels
on the container.

---

## Infrastructure

**VPS** — Hetzner Cloud, single machine, shared-CPU x86 AMD, Ubuntu 24.04.4 LTS.
- 2 vCPUs (shared)
- 3.7 GB RAM (~3.1 GB available)
- 75 GB disk (~69 GB free)
- No swap

**CI/CD** — `git push main` triggers:
1. Ruff lint + Docker Compose validation (gates the build)
2. Docker Buildx → image pushed to GHCR (GitHub Container Registry, public)
3. SSH into VPS → `docker compose pull && docker compose up -d`

Full push-to-live cycle takes ~50 seconds. Every project under `projects/` can plug into this
pipeline with minimal config changes.

**Domain** — `tarik-lab.dev`. Flat subdomain scheme: `<project>.tarik-lab.dev`. Wildcard A
record already points to the VPS, so new subdomains resolve immediately.

---

## What is easily addable

Anything that runs in a Docker container and exposes an HTTP port can be live in one session:

- **Databases**: Postgres, MySQL, SQLite (file-backed volume), ClickHouse
- **Caches / queues**: Redis, RabbitMQ, Kafka (resource-heavy)
- **Object storage**: MinIO (S3-compatible, already planned as CP6 — volume placeholder exists
  in the infrastructure compose)
- **Monitoring**: Prometheus + Grafana + Loki already planned as CP5, compose placeholders exist
- **Schedulers / orchestrators**: Airflow (heavy), Prefect, plain cron via a Python container
- **Notebooks**: JupyterLab (useful for exploration, not for production serving)
- **Any language / framework**: Go, Node, Rust — if it runs in a container, it deploys

The constraint on adding backing services (Postgres, Redis, MinIO) is RAM. Current available:
~3.1 GB. A typical project with FastAPI + Postgres + a small data workload fits comfortably.
Running Kafka + Airflow + MinIO simultaneously would be tight.

---

## Confirmed working patterns

- **Python FastAPI** — slim Docker image, non-root user, uvicorn, `/health` endpoint, env-file
  config. This is the proven template already in use.
- **Scheduled Python jobs** — a container with a cron-like loop or a simple `schedule` library
  calling an API or scraping data on an interval.
- **File-based pipelines** — ingest a file (CSV, JSON, Parquet), transform, write output;
  trivially containerized.
- **Postgres-backed APIs** — FastAPI + SQLModel/SQLAlchemy + Postgres in a private network,
  only the API surface is public.

---

## Constraints to keep in mind

- **Single machine** — no fault tolerance, no horizontal scaling. Fine for a portfolio project.
- **Shared CPU** — CPU-intensive workloads (ML training, heavy Spark jobs) will saturate the
  VPS. Inference on small models is fine; training is not.
- **3.7 GB RAM, no swap** — each service you add competes for the same pool.
- **No orchestrator** — no Kubernetes, no Swarm. Everything is plain Docker Compose. This is
  a feature (simplicity) and a constraint (no autoscaling, no rolling updates beyond
  `up -d`).
- **Public by default** — every service with Traefik labels is reachable on the internet. Any
  admin or internal tool must be explicitly gated (basic auth, IP allowlist, or put on the
  `internal` network with no Traefik labels).

---

## Ideas already scoped (optional roadmap)

| CP | Description |
|---|---|
| CP5 | Prometheus + Grafana + Loki monitoring stack |
| CP6 | MinIO object storage + a real data pipeline project |
| CP7 | Documentation site (MkDocs or similar) |
| CP8 | Security hardening (Docker socket proxy, read-only filesystems) |

These are suggestions, not requirements. A data project that doesn't fit CP5–CP8 is perfectly
valid.
