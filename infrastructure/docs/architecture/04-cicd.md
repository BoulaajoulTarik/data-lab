# CI/CD pipeline

Every push to `main` triggers a two-stage pipeline: build + push to GHCR, then SSH deploy to the VPS.

```mermaid
graph LR
    P["git push\nmain"] --> BA

    subgraph BA["build-push.yml (parallel jobs)"]
        BD["build-push-demo"]
        BI["build-push-ingest"]
    end

    BD --> LD["ruff lint\ncompose validate\ndocker build+push"]
    BI --> LI["ruff lint\ncompose validate\ndocker build+push"]

    LD & LI --> GHCR["GHCR\nghcr.io (public)"]
    GHCR --> DA

    subgraph DA["deploy.yml (parallel jobs, on workflow_run success)"]
        DD["deploy-demo"]
        DI["deploy-ingest"]
    end

    DD --> VPSD["SSH → VPS\ndocker compose pull\ndocker compose up -d"]
    DI --> VPSI["SSH → VPS\ndocker compose pull\ndocker compose up -d"]
```

## Key design choices

- **Public GHCR images** — no pull token needed on the VPS
- **Parallel jobs** — demo and ingest build and deploy independently
- **Quality gates** — ruff lint + `docker compose config` validate before every push
- **workflow_run trigger** — deploy only fires after a fully green build
