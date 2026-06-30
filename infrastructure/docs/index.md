# tarik-lab.dev

A self-hosted data-engineering lab, built as a learning environment and public portfolio.
Every service runs on a single Hetzner VPS behind Traefik, deployed automatically on every
`git push` via GitHub Actions.

## What's running

| URL | Service |
|---|---|
| [demo.tarik-lab.dev](https://demo.tarik-lab.dev) | FastAPI demo — proof-of-routing |
| [ingest.tarik-lab.dev](https://ingest.tarik-lab.dev) | FastAPI ingest — writes Parquet to MinIO |
| [grafana.tarik-lab.dev](https://grafana.tarik-lab.dev) | Grafana — metrics + logs dashboards |
| [minio.tarik-lab.dev](https://minio.tarik-lab.dev) | MinIO S3 API |
| [console.tarik-lab.dev](https://console.tarik-lab.dev) | MinIO console |
| [portainer.tarik-lab.dev](https://portainer.tarik-lab.dev) | Portainer — container management |
| [docs.tarik-lab.dev](https://docs.tarik-lab.dev) | This site |

## Stack

- **Reverse proxy + TLS:** Traefik v3.7.5 (Let's Encrypt HTTP-01, wildcard DNS)
- **Observability:** Prometheus 3.12.0 · cAdvisor 0.55.1 · Loki 3.6.12 · Grafana 13.1.0
- **Storage:** MinIO RELEASE.2025-09-07 (S3-compatible object store)
- **Projects:** Python 3.14 · FastAPI · boto3 · pyarrow / pandas
- **CI/CD:** GitHub Actions → GHCR (public images) → SSH deploy
- **Host:** Hetzner Cloud VPS, Ubuntu 24.04, 167.233.138.193

## Repository

[github.com/BoulaajoulTarik/data-lab](https://github.com/BoulaajoulTarik/data-lab)
