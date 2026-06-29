# CP5 — Monitoring  [Optional milestone]

**Goal:** Metrics and logs in Grafana — Prometheus + cAdvisor for metrics, **Loki via the Docker
logging driver** for logs (the WSL2-friendly choice that avoids Promtail's bind-mount problem).

**Depends on:** the live stack (CP3/CP4). Best validated on the **VPS** (native Linux), where cAdvisor
reports full metrics.

**Done when:** Grafana shows live container metrics and logs for the running services. → tag `cp5`.

> **Parallelizable later:** the metrics chain (Prometheus + cAdvisor) and the logs chain (Loki + the
> Docker driver) are independent. Single-agent is still fine; this note matters only if you ever
> speed-run the optional milestones.

---

## My prep
- [ ] Set a **Grafana admin password** in local `.env` / VPS `.env` (referenced by the agent as `GF_SECURITY_ADMIN_PASSWORD`).

---

## Tasks

### 5.1 — Loki + Docker logging driver  [Builder]  [1×]
**What/Why:** *Concern D resolved by choice.* The Docker driver ships container logs straight to Loki,
sidestepping the WSL2 Promtail path issue.
**Agent prompt:**
```
Add Loki to infrastructure/docker-compose.yml with local-filesystem storage
(infrastructure/monitoring/loki/loki-config.yml), persisted to a named volume, on `web`. Then install
and configure the Loki Docker logging driver plugin: give me the install command and show the compose
`logging:` block to apply to services so their logs go to Loki. Document this in
infrastructure/monitoring/README.md. Confirm Loki /ready is ready and a test container's logs arrive.
```
**Acceptance:** a container's logs are queryable in Loki. **Effort:** 🟡

### 5.2 — Prometheus  [Builder]  [1×]
**Agent prompt:**
```
Add Prometheus + infrastructure/monitoring/prometheus/prometheus.yml (15s scrape). Jobs: prometheus,
cAdvisor, Traefik metrics (enable Traefik's metrics endpoint). Commented stub jobs for grafana/minio.
Persist TSDB to a volume; attach to `web`. Confirm targets and report UP/DOWN.
```
**Acceptance:** Prometheus up; cAdvisor + Traefik targets UP. **Effort:** 🟠

### 5.3 — cAdvisor  [Builder]  [1×]
**Agent prompt:**
```
Add cAdvisor with the standard host mounts, wired as a Prometheus target. Note in comments that on
WSL2 metrics may be partial (cgroup limits) but are complete on the native-Linux VPS. Confirm which
metrics populate in the current environment.
```
**Acceptance:** cAdvisor scraped; metrics present (full on VPS). **Effort:** 🟠

### 5.4 — Grafana (provisioned)  [Builder]  [1×]
**Agent prompt:**
```
Add Grafana with file-provisioned datasources
(infrastructure/monitoring/grafana/provisioning/datasources/datasources.yml) for Prometheus and Loki
by in-network URL. Read GF_SECURITY_ADMIN_PASSWORD from .env (add to .env.example). Route
grafana.tarik-lab.dev (websecure+le) on `web`; persist to a volume. Confirm both datasources healthy.
```
**Acceptance:** Grafana loads; datasources green. **Effort:** 🟠

### 5.5 — Starter dashboard  [Builder]  [1×]
**Agent prompt:**
```
Provision a starter dashboard (JSON under grafana/provisioning/dashboards/) showing per-container CPU
and memory (cAdvisor/Prometheus) and a Loki logs panel with a LogQL query for recent logs. Auto-load
it. Confirm it renders with live data.
```
**Acceptance:** dashboard shows live metrics + logs. **Effort:** 🟡

### 5.6 — Gate Grafana + commit  [Security review → commit]  [1×]
**Agent prompt:**
```
Confirm grafana.tarik-lab.dev requires login (no anonymous access) and isn't exposing admin without
auth. Then commit "feat: monitoring stack (prometheus/cadvisor/loki/grafana)", tag cp5, push. Update
CLAUDE.md tracker + session log.
```
**Acceptance:** Grafana gated; tag `cp5`. **Effort:** 🟢

---

## Checkpoint exit
Observability is live and reproducible (provisioned as code). Tag: `cp5`.
