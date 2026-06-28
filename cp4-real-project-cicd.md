# CP4 — Real Project + CI/CD  [Required]  ★ completion-first finish line

**Goal:** Replace the throwaway whoami with a real **FastAPI** project, and automate the whole
deploy: `git push` → GitHub Actions builds the image → pushes to GHCR → deploys to the VPS → it's
live at `demo.tarik-lab.dev`. This is the point where the lab is a real, self-updating portfolio.

**Walking-skeleton role:** put real code on the proven rails and automate the deploy hop.

**Depends on:** CP3 (the live path) — reuses the same Traefik + certs.

**Checkpoint done when:** a push to `main` auto-deploys the FastAPI app and it's live over HTTPS. →
commit, tag `cp4` and `v0.2`.

---

## Human prep
- [ ] **Add GitHub Actions secrets** (Zone 2), pasted in the GitHub UI yourself: `VPS_SSH_KEY`
      (the deploy *private* key), `VPS_HOST` (VPS IP), `VPS_USER` (4.5).
- [ ] **Confirm GHCR package visibility = public** for the image (one-time setting after first push).

> The agent references these secrets by **name** only and never sees their values.

---

## Tasks

### 4.1 — Project template `_template`  [Builder]  [1×]
**What/Why:** Every project copies this; the network/label conventions must be correct here.
**Agent prompt:**
```
Create projects/_template/: docker-compose.yml with a public app service on the external `web`
network (Traefik labels routing <project>.tarik-lab.dev over websecure+le) AND a private `internal`
network for backing services (no Traefik labels on those). Use ${PROJECT_NAME} and env vars, never
hardcoded values. Add .env.example (names only), a Makefile (up/down/logs/ps), and a README with a
"Networking rules" section. Validate `docker compose config` with a sample .env.
```
**Acceptance:** template config valid; conventions documented. **Effort:** 🟠

### 4.2 — `make new-project` + scaffold the FastAPI app  [Builder]  [1×][↻]
**Agent prompt:**
```
Implement `make new-project name=X` (copy _template -> projects/X, substitute PROJECT_NAME, guard
against missing name / existing dir). Then create projects/demo as a minimal FastAPI app: a / route
returning a small JSON including a version string, and a /health route. Public service on `web` with
Traefik labels for demo.tarik-lab.dev. Read config from .env. Bring it up locally with
`make project-up name=demo` and confirm Traefik routes demo.localhost to it.
```
**Acceptance:** FastAPI app routes locally via Traefik; new-project guards work. **Effort:** 🟡

### 4.3 — Dockerfile for the FastAPI app  [Builder]  [1×]
**Agent prompt:**
```
Add a production Dockerfile to projects/demo: slim Python base, multi-stage if helpful, non-root
user, a HEALTHCHECK hitting /health, uvicorn entrypoint. Keep the image small. Build it locally and
run the container to confirm /health responds.
```
**Acceptance:** image builds; container healthy. **Effort:** 🟡

### 4.4 — `build-push.yml` → GHCR (public)  [Builder]  [1×]
**Agent prompt:**
```
Create .github/workflows/build-push.yml. On push to main (and build-only on PRs): checkout, Buildx,
log in to ghcr.io with the built-in GITHUB_TOKEN (permissions packages: write, contents: read), build
projects/demo and tag ghcr.io/<owner>/data-lab-demo:latest and :${{ github.sha }}, push on main only.
Add build caching. Reference secrets by name only. Explain how I confirm the image in GHCR and how to
make the package public once.
```
**Acceptance:** a push produces a GHCR image (latest + sha). **Effort:** 🟠

### 4.5 — Add GitHub Actions secrets  [Human]  [1×]
**What/Why:** Zone 2 credentials for the deploy hop. **How:** repo → Settings → Secrets and variables
→ Actions → add `VPS_SSH_KEY`, `VPS_HOST`, `VPS_USER`. Paste values yourself.
**Acceptance:** three secrets exist with the exact names the workflow uses.

### 4.6 — `deploy.yml` → VPS  [Builder]  [1×]
**Agent prompt:**
```
Create .github/workflows/deploy.yml triggered after build-push succeeds on main. Steps: set up SSH
from secret VPS_SSH_KEY (never echo it); SSH to ${{ secrets.VPS_USER }}@${{ secrets.VPS_HOST }}; on
the VPS pull the new image and run `docker compose pull && docker compose up -d` in the demo deploy
dir; use --quiet logins; never print secrets. Validate the YAML; I'll test it live in 4.8.
```
**Acceptance:** workflow valid; references secrets by name. **Effort:** 🔴

### 4.7 — CI quality gates  [Builder]  [1×]
**Agent prompt:**
```
Add gates to build-push.yml before the push step: validate all compose files with `docker compose
config`, run ruff on projects/demo, fail the job on any error so a broken build never ships.
```
**Acceptance:** a deliberate lint error fails the job; clean code passes. **Effort:** 🟡

### 4.8 — First automated end-to-end deploy  [Operator]  [1×]
**What/Why:** Replace whoami with the real app via the pipeline.
**Agent prompt:**
```
On the VPS, set up the demo deploy directory (compose referencing the GHCR image + Traefik labels for
demo.tarik-lab.dev). Then push a visible change to projects/demo on main and watch the full chain:
build-push -> GHCR -> deploy.yml -> VPS pulls -> container restarts. Verify https://demo.tarik-lab.dev
shows the new version with a valid cert, and retire the whoami route. Diagnose any failing hop (SSH
auth, GHCR pull, compose path, restart) and report the precise fix without touching secrets.
```
**Acceptance:** `git push` results in the FastAPI app live at `https://demo.tarik-lab.dev`. **Effort:** 🔴

### 4.9 — Security review  [Security review]  [1×]
**Agent prompt:**
```
Security review: confirm no secret values appear in Actions logs, no .env committed, the VPS pulls
only the intended public image, admin UIs still gated. List findings and fix.
```
**Acceptance:** clean review. **Effort:** 🟡

### 4.10 — Commit + tag  [Scribe → commit]  [1×]
**Agent prompt:**
```
Commit "feat: FastAPI project with CI/CD auto-deploy", tag cp4 and v0.2, push. Update CLAUDE.md State
Tracker (CP4 ☑) and session log. Note in CLAUDE.md that the required path is COMPLETE and CP5+ are
optional.
```
**Acceptance:** tags `cp4` + `v0.2`; tracker shows required path complete. **Effort:** 🟢

---

## Checkpoint exit
**The lab is a live, self-updating portfolio.** Push code → it deploys itself → it's public over
HTTPS. Everything beyond here (CP5–CP8) is optional enrichment you can add anytime without rework,
because it all attaches to the same `web` network and Traefik labels. Tag: `cp4` / `v0.2`.
