# Networking conventions

## `web` — the shared external network

`web` is a single Docker network shared by every stack in this lab. Traefik joins it, and any
service Traefik must route to also joins it. It is created once, outside of any compose file:

```
docker network create web
```

Because it's external, no compose file owns its lifecycle — `docker compose down` never deletes it.

## `internal` — per-project private networks

Services that don't need a public route (databases, internal workers) join a private `internal`
network instead, scoped to their own project's compose file. Internal services carry **no** Traefik
labels and are unreachable from the outside.

## Referencing `web` in compose

```yaml
networks:
  web:
    external: true
  internal:
    driver: bridge

services:
  my-public-service:
    networks: [web]
    labels:
      - "traefik.enable=true"
      # ...routing labels...

  my-private-service:
    networks: [internal]
```

## Rule of thumb

- Needs a `*.tarik-lab.dev` hostname → join `web`, add Traefik labels.
- Internal-only (DB, cache, worker) → join `internal`, no Traefik labels.
