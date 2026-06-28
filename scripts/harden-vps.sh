#!/usr/bin/env bash
#
# harden-vps.sh — baseline hardening for a fresh Ubuntu Hetzner VPS (CP3, task 3.2).
#
# >>> REVIEW THIS SCRIPT YOURSELF BEFORE RUNNING IT. Run it AS ROOT, ONCE, over SSH on the VPS. <<<
# >>> Lines marked "DOUBLE-CHECK" change things that can lock you out — read them first. <<<
#
# What it does, in order:
#   1. Creates a sudo user (so you stop using root for daily SSH).
#   2. Copies root's authorized_keys (your data-lab-deploy public key) to that new user.
#   3. Configures ufw to allow only SSH(22)/HTTP(80)/HTTPS(443).
#   4. Disables SSH root login and password auth (key-only from then on).
#   5. Enables unattended-upgrades for security patches.
#
# Does NOT touch: SSH keys (no key material is read, generated, or copied here besides the
# authorized_keys file), firewall rules beyond 22/80/443, or anything outside this VPS.

set -euo pipefail

# ---------------------------------------------------------------------------
# 0. Config — DOUBLE-CHECK this username before running.
# ---------------------------------------------------------------------------
NEW_USER="deploy"   # DOUBLE-CHECK: the sudo user you'll SSH in as after this script runs.

if [[ "$EUID" -ne 0 ]]; then
  echo "Run this as root (e.g. via the SSH session you already have as root)." >&2
  exit 1
fi

# ---------------------------------------------------------------------------
# 1. Create a sudo user.
# Risk mitigated: running everything as root daily widens the blast radius of any
# mistake or compromised process to the whole system, with no separation of privilege.
# ---------------------------------------------------------------------------
if id "$NEW_USER" &>/dev/null; then
  echo "[1/5] User '$NEW_USER' already exists, skipping creation."
else
  adduser --disabled-password --gecos "" "$NEW_USER"
  usermod -aG sudo "$NEW_USER"
  echo "[1/5] Created sudo user '$NEW_USER'."
fi

# ---------------------------------------------------------------------------
# 2. Give the new user the same SSH key root was provisioned with.
# DOUBLE-CHECK: this copies root's authorized_keys (your data-lab-deploy PUBLIC key,
# which Hetzner attached at VPS creation) — no private key material is touched.
# Without this step, disabling root login below would lock you out entirely.
# ---------------------------------------------------------------------------
install -d -m 700 -o "$NEW_USER" -g "$NEW_USER" "/home/$NEW_USER/.ssh"
cp /root/.ssh/authorized_keys "/home/$NEW_USER/.ssh/authorized_keys"
chmod 600 "/home/$NEW_USER/.ssh/authorized_keys"
chown "$NEW_USER:$NEW_USER" "/home/$NEW_USER/.ssh/authorized_keys"
echo "[2/5] Copied authorized_keys to '$NEW_USER'."

# ---------------------------------------------------------------------------
# 3. Firewall: allow only SSH/HTTP/HTTPS.
# Risk mitigated: an internet-facing host with an unrestricted firewall exposes every
# listening service (including ones you forgot about) to mass internet scanning.
# DOUBLE-CHECK: if you SSH on a non-default port, add it here BEFORE enabling ufw,
# or you will be locked out.
# ---------------------------------------------------------------------------
ufw allow 22/tcp
ufw allow 80/tcp
ufw allow 443/tcp
ufw --force enable
echo "[3/5] ufw enabled, allowing only 22/80/443."

# ---------------------------------------------------------------------------
# 4. Disable root login and password auth over SSH.
# Risk mitigated: root logins and password auth are the two most common targets of
# automated SSH brute-force scanning on any public IPv4 address.
# DOUBLE-CHECK: this is the step that removes your fallback. Confirm step 2 actually
# put your key in place (e.g. open a SECOND terminal and `ssh deploy@<ip>` to verify
# it works) before you close your current root session.
# ---------------------------------------------------------------------------
SSHD_CONFIG="/etc/ssh/sshd_config"
sed -i 's/^#\?PermitRootLogin.*/PermitRootLogin no/' "$SSHD_CONFIG"
sed -i 's/^#\?PasswordAuthentication.*/PasswordAuthentication no/' "$SSHD_CONFIG"
sshd -t   # validate config syntax before reloading — abort below if this fails
systemctl reload ssh
echo "[4/5] Root login and password auth disabled; sshd reloaded."

# ---------------------------------------------------------------------------
# 5. Unattended security upgrades.
# Risk mitigated: an internet-facing box that misses security patches accumulates
# known, exploitable CVEs the longer it runs unattended.
# ---------------------------------------------------------------------------
apt-get update -y
apt-get install -y unattended-upgrades
dpkg-reconfigure -f noninteractive unattended-upgrades
echo "[5/5] unattended-upgrades installed and enabled."

echo
echo "Done. From a NEW terminal (keep this session open until you confirm), verify:"
echo "  ssh -i ~/.ssh/data-lab-deploy $NEW_USER@<VPS_IP>"
echo "Only after that succeeds should you close this root session."
