# CP6 — MinIO + a Data Project  [Optional milestone]

**Goal:** Add S3-compatible object storage (MinIO) to the shared infra, then build a small data
project that actually *uses* it — turning the lab from "a web app" into "a data platform" and giving
you a more substantive portfolio piece.

**Depends on:** the live stack (CP3/CP4). Pairs well with CP5 (you'll see the new project's metrics/logs).

**Done when:** MinIO is up and a data project reads/writes objects via the S3 API. → tag `cp6`.

---

## My prep
- [ ] Generate strong **MinIO root credentials** and place them in `.env` (`MINIO_ROOT_USER`, `MINIO_ROOT_PASSWORD`).

---

## Tasks

### 6.1 — MinIO (API + console)  [Builder]  [1×]
**Agent prompt:**
```
Add MinIO to infrastructure/docker-compose.yml: root creds from .env (add keys to .env.example),
persist to a named volume, on `web`, with two Traefik routers — S3 API at minio.tarik-lab.dev and the
console at console.tarik-lab.dev (websecure+le). Validate config; remind me to set strong creds in
.env. After start, confirm the console loads and the S3 endpoint responds.
```
**Acceptance:** MinIO console loads; S3 endpoint reachable. **Effort:** 🟡

### 6.2 — Create a bucket + scoped access  [Builder + Me]  [1×]
**What/Why:** Don't use root creds in app code. **How:** agent scripts bucket + a scoped access key
via the MinIO client; you confirm/store the key in the project `.env`.
**Agent prompt:**
```
Using the MinIO client (mc) against the running MinIO, create a bucket `demo-data` and a scoped
access key/policy limited to that bucket. Output the steps so I can run the key-creation myself and
store the key in the project .env (do not hardcode or commit it). Document in the project README.
```
**Acceptance:** `demo-data` bucket exists; a scoped key is created (by you). **Effort:** 🟡

### 6.3 — Data project that uses S3  [Builder]  [1×][↻]
**Agent prompt:**
```
With `make new-project name=ingest`, scaffold a small Python data project that: pulls a public sample
dataset (or generates synthetic rows), writes it as Parquet to the MinIO `demo-data` bucket via the
S3 API (boto3/s3fs, endpoint from .env), and exposes a tiny FastAPI/CLI summary of what it wrote.
Public service on `web` (ingest.tarik-lab.dev), creds from .env (scoped key, not root). Run it and
confirm objects appear in MinIO.
```
**Acceptance:** the project writes objects visible in the MinIO console. **Effort:** 🟠

### 6.4 — Wire CI/CD for the new project  [Builder]  [1×]
**Agent prompt:**
```
Extend the CI/CD pattern to projects/ingest: build+push its image to GHCR and deploy it to the VPS
the same way as demo. Reuse the existing workflows (matrix or a parallel workflow). Confirm a push
deploys ingest live.
```
**Acceptance:** push deploys `ingest` to the VPS. **Effort:** 🟠

### 6.5 — Security review + commit  [Security review → commit]  [1×]
**Agent prompt:**
```
Confirm the data project uses the scoped MinIO key (not root), no creds committed, MinIO console is
gated. Commit "feat: MinIO storage + ingest data project", tag cp6, push. Update CLAUDE.md tracker +
session log.
```
**Acceptance:** scoped creds only; tag `cp6`. **Effort:** 🟢

---

## Checkpoint exit
The lab now stores and processes data, with a project that demonstrates the S3 workflow end to end.
Tag: `cp6`.
