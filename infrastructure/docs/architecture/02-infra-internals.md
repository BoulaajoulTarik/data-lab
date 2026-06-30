# Shared infrastructure internals

All services share the external `web` Docker network. Traefik is the only service that
binds host ports (80/443). Every other service is reached by Traefik via the network.

```mermaid
graph TD
    subgraph web["Docker network: web (external)"]
        TR["Traefik v3.7.5\n:80 :443"]

        subgraph routing["Routing"]
            PT["Portainer 2.39.4\nportainer.tarik-lab.dev"]
            WH["whoami v1.11.0\nwhoami.tarik-lab.dev"]
        end

        subgraph monitoring["Monitoring"]
            GF["Grafana 13.1.0\ngrafana.tarik-lab.dev"]
            PR["Prometheus 3.12.0"]
            CA["cAdvisor 0.55.1"]
            LK["Loki 3.6.12"]
        end

        subgraph storage["Storage"]
            MN["MinIO\nminio.tarik-lab.dev\nconsole.tarik-lab.dev"]
        end

        subgraph projects["Projects"]
            DM["demo\ndemo.tarik-lab.dev"]
            IN["ingest\ningest.tarik-lab.dev"]
        end

        DC["docs\ndocs.tarik-lab.dev"]
    end

    TR --> PT & WH & GF & MN & DM & IN & DC
    GF --> PR & LK
    PR --> CA & TR
    IN -- "S3 API" --> MN
```
