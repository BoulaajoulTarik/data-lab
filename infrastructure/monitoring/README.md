# Monitoring stack

Container metrics and logs via Prometheus + cAdvisor + Loki + Grafana.

| Service    | URL                              | Auth              |
|------------|----------------------------------|-------------------|
| Grafana    | https://grafana.tarik-lab.dev    | admin + env var   |
| Prometheus | internal only (no public route)  | —                 |
| Loki       | internal only (no public route)  | —                 |

---

## Loki Docker logging driver

Container logs are shipped to Loki by the Docker logging driver plugin — no
Promtail sidecar needed. The plugin runs at the Docker daemon level, so it
must be installed on **every host** (VPS and local machine) before starting
the stack.

### Install (run once per host)

**VPS (amd64):**
```bash
docker plugin install grafana/loki-docker-driver:3.7.2-amd64 \
  --grant-all-permissions --alias loki
docker plugin ls   # confirm loki ENABLED
```

**Local WSL2 (amd64):**
```bash
docker plugin install grafana/loki-docker-driver:3.7.2-amd64 \
  --grant-all-permissions --alias loki
docker plugin ls
```

### How it works

Each service in `docker-compose.yml` carries this logging block (via the
`x-loki-logging` YAML anchor):

```yaml
logging:
  driver: loki
  options:
    loki-url: "http://localhost:3100/loki/api/v1/push"
    loki-batch-size: "400"
    loki-retries: "3"
    loki-min-backoff: "1s"
    loki-max-backoff: "10s"
    loki-timeout: "10s"
```

Loki's port 3100 is bound to `127.0.0.1` on the host so the daemon can reach
it. Grafana reaches Loki by container name (`http://loki:3100`) over the `web`
network.

### Upgrade the plugin

```bash
docker plugin disable loki
docker plugin upgrade loki grafana/loki-docker-driver:<new-version>-amd64 \
  --grant-all-permissions
docker plugin enable loki
```

---

## Directory layout

```
monitoring/
  loki/
    loki-config.yml       # single-binary, filesystem storage
  grafana/
    provisioning/
      datasources/        # auto-wired Prometheus + Loki sources  (task 5.4)
      dashboards/         # starter dashboard JSON                (task 5.5)
  prometheus/
    prometheus.yml        # scrape config                         (task 5.2)
```
