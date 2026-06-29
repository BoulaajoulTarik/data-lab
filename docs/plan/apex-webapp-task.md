# Apex Web App — Deploy Portfolio at `tarik-lab.dev`  [Standalone — outside CP1–CP8]

**Status:** content validated. Ready for an agent (with project context) to execute on my explicit
go-ahead.

**Goal:** serve the existing static portfolio page as the home page at the bare domain
`https://tarik-lab.dev`, reusing the proven Traefik + ACME + `web`-network mechanism from CP3
(whoami/portainer/traefik dashboard already work this way).

**This is intentionally separate from CP4.** CP4's `projects/demo` (FastAPI, `demo.tarik-lab.dev`,
GitHub Actions CI/CD) is the *required-path* data project. This task is a different, personal
portfolio project that happens to share the same `projects/` folder convention and the same
Traefik/`web`-network mechanism — it does **not** depend on CP4's tooling (`_template`,
`make new-project`) and must not be confused with, or block, CP4's progress.

---

## Why the apex domain (deliberate exception)

`CLAUDE.md`'s Locked Decisions specify a **flat subdomain scheme** (`service.tarik-lab.dev`) and say
nothing about the bare domain. This task deliberately serves content at the apex instead —
confirmed with me. DNS already supports this with no new records needed: the wildcard
`*.tarik-lab.dev` record and the apex `@` record are two separate DNS entries (a wildcard does not
match a bare domain), and both were already pointed at the VPS IP back in CP3 task 3.6. Routing-wise
nothing is special: Traefik's docker provider treats `Host(`tarik-lab.dev`)` exactly like any
subdomain rule, and the `le` certresolver issues a dedicated HTTP-01 cert for it, same as every other
hostname already live.

## Source content (already built and validated)

`infrastructure/docs/webapp_doc/` — a complete, self-contained, single-file static portfolio:

- `index.html` — the page to serve (warm-dark design, hero + 6 sections: work, skills, ADRs,
  timeline, writing, contact). No build step, no framework, no server-side logic.
- `resume/RESUME_TARIK_BOULAAJOUL.pdf` — CV, linked from the page's download button.
- `design-system.md`, `content-fr.md`, `agent-handoff.md`, `README.md` — design spec, French
  translation, feature roadmap, and usage notes for whoever continues this work.

Already fixed in this content (this session): CV download points to the PDF (was a dead link to a
nonexistent file), LinkedIn URL corrected to
`https://www.linkedin.com/in/tarik-boulaajoul-8b1b6a149/` (was an incomplete placeholder), GitHub
link added (`https://github.com/BoulaajoulTarik`, was missing). The phone number is intentionally
public — confirmed with me, not an oversight.

**Known follow-ups not required for this deploy:** the 5-feature interactive roadmap in
`agent-handoff.md` (SQL Playground, Lineage Explorer, Cost Comparator, Data Quality Test Runner,
"Tune This Query" puzzle) is future work — ship the static page first, build those later. The three
blog post teasers in `#writing` have no real article links yet — left as placeholders by design.

## What to build

1. Create `projects/webapp/` containing:
   - The static site content (`index.html` + `resume/`), moved or copied from
     `infrastructure/docs/webapp_doc/`.
   - A `docker-compose.yml`: a minimal static file server (a pinned, current-stable image — follow
     the repo convention of pinning to the actual current stable tag, never `latest`) serving the
     content, joined to the external `web` network, with Traefik labels routing
     `Host(`tarik-lab.dev`)` over `websecure` with `tls.certresolver=le`.
2. Add dedicated targets to the **root** `Makefile`: `webapp-up`, `webapp-down`, `webapp-logs` —
   deliberately separate from the generic `project-up name=X` / `project-down name=X` targets CP4
   will use for data projects, so the two tracks never collide or get confused. These call
   `docker compose -f projects/webapp/docker-compose.yml <up -d | down | logs -f>`.
3. Update **CLAUDE.md's Locked Decisions** to record the exception: the apex `tarik-lab.dev` serves
   this portfolio app specifically; the flat-subdomain scheme still governs every other service.

## Restrictions (hard constraints for whoever executes this)

- **Do not edit existing `infrastructure/` files** (`docker-compose.yml`, `traefik.yml`, etc.) — no
  central wiring is needed; the new service is self-contained and only needs the `web` network,
  which already exists.
- **Do not commit or tag anything without my explicit approval** — draft the changes and let me
  review and run the commit, same posture as other my-prep boundaries in `CLAUDE.md`.
- **Do not touch or interact with CP4 work at all** — no edits to `projects/_template`,
  `make new-project`, CI/CD workflows, or the CP4 State Tracker rows. If CP4 is in progress
  concurrently, avoid any file it's also touching.
- **Do the Makefile + Locked Decisions edits last** — only after I have tested and validated
  the deployed page over HTTPS, not as a first step.

## Acceptance check

- `make webapp-up` brings the container up; it joins `web`; Traefik issues/renews a valid Let's
  Encrypt cert for `tarik-lab.dev`.
- `https://tarik-lab.dev` serves the portfolio page; CV download, LinkedIn, and GitHub links all
  resolve correctly.
- `make webapp-down` cleanly stops it.
- `CLAUDE.md` Locked Decisions documents the apex exception; State Tracker and CP4 files are
  untouched by this work.
