# `_template`

Starting point for every project in `projects/`. Copied by `make new-project name=X` (root
Makefile), which substitutes `${PROJECT_NAME}` and lands the result at `projects/X`.

## Networking rules

- **Public service (`app`)** joins the shared external `web` network and carries Traefik labels
  routing `<PROJECT_NAME>.tarik-lab.dev` over the `websecure` entrypoint with the `le`
  certresolver. This is the only way in from the outside.
- **Backing services** (databases, caches, workers) join the project-local `internal` network
  instead and carry **no** Traefik labels — they are unreachable from outside the Docker host.
- Never put Traefik labels on a backing service, and never expose a backing service's port to the
  host directly; reach it only from `app` over `internal`.
- `web` is `external: true` — it's created once outside any compose file (see
  `infrastructure/docs/conventions/networking.md`) and is never owned or torn down by a project's
  `docker compose down`.

## Usage

```
make up      # start this project's stack
make down    # stop it
make logs    # tail logs
make ps      # show running containers
```

Configuration comes from `.env` (copy `.env.example` and fill in real values — never commit `.env`).
