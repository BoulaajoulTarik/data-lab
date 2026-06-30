# Project anatomy

The structure of a single data project — using `ingest` as the example.

```mermaid
graph TD
    subgraph repo["projects/ingest/ (repo)"]
        APP["app/\n  main.py — FastAPI routes\n  s3.py — boto3 + Parquet logic"]
        DF["Dockerfile\n(multi-stage, non-root)"]
        DC["docker-compose.yml\n(dev — build: .)"]
        DCP["docker-compose.prod.yml\n(prod — GHCR image)"]
        EX[".env.example\n(var names only — committed)"]
    end

    subgraph vps["VPS — runtime"]
        subgraph web_net["web network"]
            TR["Traefik\ningest.tarik-lab.dev"]
            CT["ingest container\n(GHCR image)"]
            MN["MinIO\nminio.tarik-lab.dev"]
            LK["Loki\nlocalhost:3100"]
        end
    end

    DCP -- "CI/CD rsync + deploy.yml" --> CT
    CT -- "Traefik labels → routing" --> TR
    CT -- "boto3 S3 API\n(scoped key)" --> MN
    CT -- "Loki Docker\nlogging driver" --> LK
```

## Network rules

- **`web` (external):** public services only — join it to get a Traefik route
- **`internal` (per-project):** backing services (DBs, workers) — no Traefik labels, not routable

## Secrets model

| Zone | Where | How |
|---|---|---|
| Zone 1 | Local `.env` (gitignored) | Used by `make project-up` |
| Zone 2 | GitHub Actions secrets | Used by CI/CD workflows |
| Zone 3 | VPS `~/projectname/.env` | Set manually, never in git |
