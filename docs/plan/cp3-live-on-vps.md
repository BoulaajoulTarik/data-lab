# CP3 — LIVE on the VPS  [Required]  ★ the milestone

**Goal:** The same Traefik + whoami stack from CP2, running on a public Hetzner VPS, reachable over
**real HTTPS** at `whoami.tarik-lab.dev`, with admin UIs auth-gated. This proves the entire public
deploy path before any custom code exists.

**Walking-skeleton role:** cross the finish line *once* with a throwaway container. After this,
shipping the real app is cheap.

**Depends on:** CP2.

**Checkpoint done when:** `https://whoami.tarik-lab.dev` loads from the public internet with a valid
Let's Encrypt certificate, and Traefik dashboard + Portainer require auth. → commit, tag `cp3` and
`v0.1`.

---

## My prep (security-sensitive — these are mine)

- [ ] **Create a Hetzner Cloud account**, add billing (you confirmed hourly billing = cents to test).
- [ ] **Provision a VPS** (smallest shared instance, ~€3.79/mo, German datacenter), Ubuntu LTS, with your `data-lab-deploy` **public** key attached. Note the **public IP** (3.1).
- [ ] **Run the hardening script** the agent drafts (3.2) — you execute it; it's security settings.
- [ ] **Add the wildcard DNS A record** at your registrar (3.6): `*.tarik-lab.dev` and `tarik-lab.dev` → VPS IP.
- [ ] Have your **ACME email** ready for Let's Encrypt (3.5).

> Reminder: when you finish testing and want to stop billing, **delete** the server (and its IPv4),
> don't just power it off.

---

## Tasks

### 3.1 — Provision the VPS  [Me]  [1×][PRE]
**What/Why:** The always-on public host. **How:** Hetzner console → create server → Ubuntu → attach
your deploy public key → note the IP.
**Acceptance:** you can `ssh -i ~/.ssh/data-lab-deploy <user>@<VPS_IP>` from WSL2.

### 3.2 — Harden the VPS  [Operator drafts → I run]  [1×]
**What/Why:** A public server is probed constantly; this is the baseline. **How:** agent writes a
commented script; **you review and run it.**
**Agent prompt:**
```
Produce a commented bash hardening script for a fresh Ubuntu Hetzner VPS that I will REVIEW and RUN
MYSELF: create a sudo user, configure ufw to allow only 22/80/443, disable root login and password
auth in sshd_config, enable unattended-upgrades. Annotate each step with what it does and the risk it
mitigates; flag lines I must double-check. Do NOT execute it, do NOT touch SSH keys.
```
**Acceptance:** after you run it, password SSH is disabled, only 22/80/443 open. **Effort:** 🟢 (draft)

### 3.3 — Install Docker + Compose on the VPS  [Operator]  [1×]
**Agent prompt:**
```
Over my authenticated SSH session, install Docker Engine + Compose v2 plugin on the Ubuntu VPS via
the official Docker apt repo (not snap), add my sudo user to the docker group, verify with
`docker run --rm hello-world`. Report versions. Do not modify firewall or SSH settings.
```
**Acceptance:** `hello-world` runs on the VPS. **Effort:** 🟡

### 3.4 — Bring the infra repo to the VPS + create `web`  [Operator]  [1×]
**Agent prompt:**
```
On the VPS: create the external `web` network, then get the infrastructure stack onto the box (clone
the public GitHub repo, or pull just infrastructure/). I will provide the server-side .env values
(reference keys by name). Do not start it yet — the next task enables HTTPS first.
```
**Acceptance:** repo present on VPS; `web` network exists. **Effort:** 🟡

### 3.5 — Enable Traefik HTTP-01 certs + HTTPS  [Builder]  [1×]
**What/Why:** Real certificates. *Concern B resolved:* the VPS has a public IP, so Traefik does the
HTTP-01 challenge on port 80 and serves HTTPS. `.dev` requires HTTPS anyway — this satisfies it.
**Agent prompt:**
```
Enable the Let's Encrypt HTTP-01 certresolver in the VPS Traefik config (uncomment the CP3 block from
CP2). Specifics:
- certresolver `le`, httpChallenge on the `web` entrypoint, ACME email <YOUR_EMAIL>.
- Persist acme.json to a named volume with 600 permissions.
- Turn ON the web->websecure redirect now.
- Switch the whoami, portainer, and traefik-dashboard routers to entrypoint websecure with
  certresolver le and their tarik-lab.dev hostnames (whoami.tarik-lab.dev, portainer.tarik-lab.dev,
  traefik.tarik-lab.dev).
Note clearly that HTTP-01 issues per-hostname certs (no wildcard cert needed) and the wildcard DNS
record just makes the hostnames resolve. Validate config. Don't start until DNS (3.6) is live.
```
**Acceptance:** config valid; routers point at `*.tarik-lab.dev` over websecure+le. **Effort:** 🟠

### 3.6 — Add the wildcard DNS A record  [Me]  [1×]
**What/Why:** Make every subdomain resolve to the VPS so HTTP-01 can validate and users can connect.
**How:** at the registrar's DNS editor add: `A  *  <VPS_IP>` and `A  @  <VPS_IP>` (wildcard + apex).
**Acceptance:** `dig whoami.tarik-lab.dev` (or `nslookup`) returns the VPS IP.

### 3.7 — Launch on the VPS + verify HTTPS  [Operator]  [1×]
**Agent prompt:**
```
On the VPS, start the infra stack. Watch Traefik request the Let's Encrypt cert for
whoami.tarik-lab.dev via HTTP-01. Verify from the public internet that https://whoami.tarik-lab.dev
loads with a valid cert (check issuer = Let's Encrypt, no warnings). If issuance fails, diagnose
(port 80 reachable? DNS propagated? acme.json perms? LE rate limit?) and fix. Report the result.
```
**Acceptance:** `https://whoami.tarik-lab.dev` is publicly live with a valid cert. **Effort:** 🟠

### 3.8 — Security review of the public surface  [Security review]  [1×]
**Agent prompt:**
```
Security review of the live VPS: confirm only 22/80/443 are open; the Traefik dashboard and Portainer
require basic-auth (not openly reachable); no .env or secrets on the box are world-readable; acme.json
is 600. List findings; fix anything ungated and re-verify.
```
**Acceptance:** admin UIs gated; ports correct; no exposed secrets. **Effort:** 🟡

### 3.9 — Commit + tag the milestone  [Scribe → commit]  [1×]
**Agent prompt:**
```
Commit "feat: live on VPS over HTTPS (whoami)", tag cp3 and v0.1, push. Update CLAUDE.md State
Tracker (CP3 ☑, note the VPS IP placeholder and live URL) and add a session-log line.
```
**Acceptance:** tags `cp3` + `v0.1`; tracker updated. **Effort:** 🟢

---

## Checkpoint exit
**You have a public HTTPS URL that works.** The hard, unfamiliar part — VPS, firewall, certs, public
DNS — is proven with a throwaway container. Everything from here is swapping in real code on rails
that already work. Tag: `cp3` / `v0.1`.
