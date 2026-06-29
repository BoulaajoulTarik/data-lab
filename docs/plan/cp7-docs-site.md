# CP7 — Docs Site + Architecture Diagrams  [Optional milestone]

**Goal:** A polished MkDocs Material site served at `docs.tarik-lab.dev`, containing the five
architecture diagrams. This is the part that makes the portfolio *legible* to a reviewer — the story,
not just the running services.

**Depends on:** a meaningful amount built (ideally after CP3/CP4, better after CP5/CP6 so the diagrams
reflect reality).

**Done when:** the docs site is live over HTTPS with the five diagrams in its nav. → tag `cp7`.

---

## My prep
- [ ] None (all content/config). Just decide if the docs site should be public or gated (default: public — it's a portfolio).

---

## Tasks

### 7.1 — MkDocs Material site  [Builder]  [1×]
**What/Why:** Docs-as-code, served as a site. **How:** for public serving, build static and serve via
a lightweight server rather than the dev server (*Concern F*).
**Agent prompt:**
```
Add documentation serving for infrastructure/docs/. Create mkdocs.yml (Material theme) and a starter
nav (Overview, Architecture, Operations, Security). For PUBLIC serving, run `mkdocs build` and serve
the static site/ via a small nginx container (not `mkdocs serve`). Add a Traefik route
docs.tarik-lab.dev (websecure+le) on `web`. Confirm the site builds and loads.
```
**Acceptance:** docs site loads over HTTPS. **Effort:** 🟡

### 7.2 — Five architecture diagrams (Mermaid)  [Builder]  [1×]
**What/Why:** The visual portfolio anchor; as-built, versioned with the system.
**Agent prompt:**
```
Generate five Mermaid diagrams as files under infrastructure/docs/architecture/, reflecting the
AS-BUILT system, and add them to the MkDocs nav:
1. Ecosystem overview — local machine, GitHub, GHCR, the internet, the Hetzner VPS.
2. Shared infrastructure internals — Traefik, Portainer, MinIO, docs + monitoring (grafana/
   prometheus/loki/cadvisor), all on the `web` network.
3. Request routing — browser -> DNS (tarik-lab.dev) -> VPS -> Traefik (HTTP-01 TLS) -> container.
4. CI/CD — git push -> GitHub Actions build -> GHCR (public) -> SSH deploy -> VPS.
5. Project anatomy — inside one project: files, web/internal network split, links to Traefik/MinIO/
   monitoring.
Keep each focused and readable; only include components that actually exist at this point.
```
**Acceptance:** five diagrams render in the docs nav and match reality. **Effort:** 🟠

### 7.3 — Fill core docs pages  [Builder + Scribe]  [1×]
**Agent prompt:**
```
Reconcile infrastructure/docs/ with the current repo: write/refresh the Overview (what the lab is),
Operations (make commands, deploy flow, backups if present), and Security (the three-zone secrets
model, auth-gating). Keep pages skimmable. List what changed.
```
**Acceptance:** core pages accurate and present. **Effort:** 🟡

### 7.4 — Commit  [Security review → commit]  [1×]
**Agent prompt:**
```
Confirm no secrets or internal-only details (real IPs, tokens) are exposed in the public docs. Commit
"docs: site + five architecture diagrams", tag cp7, push. Update CLAUDE.md tracker + session log.
```
**Acceptance:** no sensitive data in public docs; tag `cp7`. **Effort:** 🟢

---

## Checkpoint exit
The lab now explains itself: a live docs site with architecture diagrams a reviewer can follow. Tag:
`cp7`.
