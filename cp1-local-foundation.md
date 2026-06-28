# CP1 — Local Foundation  [Required]

**Goal:** A working WSL2 + Docker toolchain and a clean, committed monorepo skeleton living at
`~/data-lab` in the Linux filesystem.

**Walking-skeleton role:** the ground everything stands on — no services yet, just a solid base.

**Depends on:** nothing (domain already registered).

**Checkpoint done when:** the skeleton is pushed to GitHub, `make help` lists the stub targets, and
`.gitignore` is proven to exclude env files. → commit, tag `cp1`.

---

## Human prep (do these first, in one sitting)

- [ ] **Install WSL2 + Ubuntu 24.04** (task 1.1 — the agent can't install its own foundation).
- [ ] **Install Docker Desktop** with the WSL2 backend, integration enabled for Ubuntu (1.3).
- [ ] **Install Claude Code inside the WSL2 Ubuntu terminal** (native installer), then `claude doctor`.
- [ ] **Create the GitHub repo** `data-lab` (private to start) and have its clone URL ready (1.5).

Everything below this line can then be handed to the agent, task by task.

---

## Tasks

### 1.1 — Install WSL2 + Ubuntu 24.04  [Human]  [1×]
**What/Why:** The Linux environment Docker and all tooling run on. **How:** elevated PowerShell
`wsl --install`, reboot, then `wsl --install -d Ubuntu-24.04` and set your Linux user.
**Acceptance:** `wsl -l -v` shows Ubuntu-24.04 running on version 2.

### 1.2 — Cap WSL2 memory/CPU  [Builder drafts → Human applies]  [1×]
**What/Why:** Keep the always-on stack from starving Windows. **How:** agent writes the file
contents; you place it and run `wsl --shutdown`.
**Agent prompt:**
```
Output the contents of a Windows %UserProfile%\.wslconfig for a 32GB machine: cap WSL2 memory to
24GB, leave 2 logical processors for Windows, set a modest swap, with comments. Then give me the
one-line apply step (wsl --shutdown). Do not try to write to the Windows filesystem yourself.
```
**Acceptance:** after applying, `free -h` in Ubuntu reflects the cap. **Effort:** 🟢

### 1.3 — Install Docker Desktop (WSL2 backend)  [Human]  [1×]
**What/Why:** Provides the Docker engine for the whole lab. **How:** install, enable "Use the WSL 2
based engine," toggle WSL Integration for Ubuntu-24.04.
**Acceptance:** `docker run --rm hello-world` succeeds inside Ubuntu.

### 1.4 — Toolchain verify script  [Builder]  [1×]
**What/Why:** Catch a missing tool now, not mid-build.
**Agent prompt:**
```
Create scripts/check-prereqs.sh for Ubuntu 24.04 WSL2. Verify docker, docker compose (v2 plugin),
make, git; print each version; exit non-zero listing anything missing plus the apt install command.
Idempotent and re-runnable. Run it and report.
```
**Acceptance:** script prints versions for all four and exits 0. **Effort:** 🟢

### 1.5 — Create GitHub repo & establish `~/data-lab`  [Human + Builder]  [1×]
**What/Why:** The working root must be in the WSL2 Linux filesystem. Move the staged Desktop files in.
**How (human):** create the GitHub repo; in Ubuntu, `cd ~ && git clone <url> data-lab` (or `git init`
in `~/data-lab` and set the remote). Then copy the staged docs (`CLAUDE.md`, `README.md`, the `cp*`
files) from the Windows Desktop into `~/data-lab` — e.g. from Ubuntu:
`cp -r /mnt/c/Users/<you>/Desktop/data-lab/* ~/data-lab/`.
**Agent prompt (after files are in place):**
```
Confirm the working directory ~/data-lab is on the Linux-native filesystem (NOT /mnt/c) and that
CLAUDE.md and the cp*.md plan files are present. Report the git remote. Do not commit yet.
```
**Acceptance:** `pwd` shows `/home/<user>/data-lab`; CLAUDE.md present; remote set. **Effort:** 🟢

### 1.6 — Monorepo skeleton  [Builder]  [1×]
**Agent prompt:**
```
In ~/data-lab create: infrastructure/{traefik,portainer,monitoring,docs,minio}, projects/_template,
.github/workflows. Add .gitkeep to empty dirs. Print the 2-level tree. Skeleton only — no configs yet.
```
**Acceptance:** tree matches; empty dirs tracked. **Effort:** 🟢

### 1.7 — Root `.gitignore`  [Builder]  [1×]
**Agent prompt:**
```
Create ~/data-lab/.gitignore. MUST use:
.env
.env.*
!.env.example
Also ignore secrets/, __pycache__/, *.pyc, .DS_Store, backups/. Comment why the negation matters.
Verify: create a temp .env.production, confirm `git status --porcelain` ignores it, delete it.
```
**Acceptance:** the temp `.env.production` is ignored; `.env.example` would be tracked. **Effort:** 🟢

### 1.8 — Root Makefile (stubs)  [Builder]  [1×]
**Agent prompt:**
```
Create ~/data-lab/Makefile (tabs for recipes). Targets: help (default, lists commands), infra-up,
infra-down, infra-logs, new-project name=X, project-up name=X, project-down name=X, logs name=X,
deploy (echo "wired in CP4"). Guard name= targets with a clear error if name is missing. Add .PHONY.
Run `make help`.
```
**Acceptance:** `make help` prints all targets; `make project-up` with no name errors cleanly. **Effort:** 🟡

### 1.9 — Place CLAUDE.md + README  [Scribe]  [1×]
**What/Why:** Ensure the anchor and index are in the repo and accurate. **How:** they're already
copied in (1.5); confirm and lightly adjust paths if needed.
**Acceptance:** CLAUDE.md and README.md at repo root, links valid. **Effort:** 🟢

### 1.10 — First commit  [Security review → commit]  [1×]
**Agent prompt:**
```
Security review before commit: confirm no .env or secret files are staged (`git status`), no
credentials in any file. Then stage all, commit "chore: monorepo skeleton + plan", push to origin
main, and create lightweight tag cp1. Report commit hash. If push needs auth I haven't set up, stop
and tell me what to configure — do not enter credentials.
```
**Acceptance:** clean push; tag `cp1` exists; no secrets committed. **Effort:** 🟢

---

## Checkpoint exit
Skeleton live on GitHub, toolchain verified, `make help` works, secrets pattern proven. Update the
State Tracker in CLAUDE.md (CP1 ☑) and append a session-log line. Tag: `cp1`.
