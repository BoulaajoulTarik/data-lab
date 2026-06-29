# `demo`

Minimal FastAPI app proving the CP4 pipeline end to end: `git push` → GitHub Actions builds the
image → pushes to GHCR → deploys to the VPS → live at `https://demo.tarik-lab.dev`.

- `GET /` — returns `{"service": "demo", "version": "<APP_VERSION>"}`.
- `GET /health` — returns `{"status": "ok"}`, used by the container `HEALTHCHECK`.

## Networking rules

- **Public service (`app`)** joins the shared external `web` network and carries Traefik labels
  routing `demo.tarik-lab.dev` over the `websecure` entrypoint with the `le` certresolver. This is
  the only way in from the outside.
- **Backing services** (databases, caches, workers) join the project-local `internal` network
  instead and carry **no** Traefik labels — they are unreachable from outside the Docker host.
- Never put Traefik labels on a backing service, and never expose a backing service's port to the
  host directly; reach it only from `app` over `internal`.
- `web` is `external: true` — it's created once outside any compose file (see
  `infrastructure/docs/conventions/networking.md`) and is never owned or torn down by
  `docker compose down`.

## Local testing

The production Traefik config (`infrastructure/docker-compose.yml`) routes only
`*.tarik-lab.dev` hostnames via the `le` ACME certresolver, which needs real internet access —
there's no local `.localhost` routing path. So locally, test the container directly instead of
through Traefik:

```
make up
docker compose exec app curl -s localhost:8000/health
```

The first real proof of Traefik routing + a valid cert is the live deploy at
`https://demo.tarik-lab.dev` (CP4 task 4.8).

## Usage

```
make up      # start this project's stack
make down    # stop it
make logs    # tail logs
make ps      # show running containers
```

Configuration comes from `.env` (copy `.env.example` and fill in real values — never commit `.env`).
