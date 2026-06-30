# Request routing

How a browser request reaches a container — from DNS through TLS termination to the app.

```mermaid
sequenceDiagram
    participant B as Browser
    participant D as DNS (*.tarik-lab.dev)
    participant T as Traefik :443 (VPS)
    participant C as Container

    B->>D: resolve service.tarik-lab.dev
    D-->>B: 167.233.138.193 (wildcard A record)
    B->>T: HTTPS request
    Note over T: TLS terminated here<br/>cert from Let's Encrypt (HTTP-01)
    T->>T: match Host() label → find container
    T->>C: HTTP proxy → container port
    C-->>T: response
    T-->>B: response (HTTPS)
```

## How Traefik discovers routes

Traefik watches the Docker socket (`/var/run/docker.sock:ro`). When a container joins the
`web` network with `traefik.enable=true` labels, Traefik automatically:

1. Creates an HTTPS router matching the `Host()` rule
2. Requests a Let's Encrypt cert via HTTP-01 on port 80
3. Proxies traffic to the container's specified port

No config reload needed — new services are picked up instantly.
