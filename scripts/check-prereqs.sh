#!/usr/bin/env bash
# Verifies the toolchain required for data-lab on Ubuntu 24.04 (WSL2).
set -uo pipefail

missing=()
ok=0

if command -v docker >/dev/null 2>&1; then
  echo "[OK] docker: $(docker --version)"
else
  echo "[MISSING] docker"
  missing+=("docker.io")
  ok=1
fi

if docker compose version >/dev/null 2>&1; then
  echo "[OK] docker compose: $(docker compose version)"
else
  echo "[MISSING] docker compose (v2 plugin)"
  missing+=("docker-compose-plugin")
  ok=1
fi

if command -v make >/dev/null 2>&1; then
  echo "[OK] make: $(make --version | head -n1)"
else
  echo "[MISSING] make"
  missing+=("make")
  ok=1
fi

if command -v git >/dev/null 2>&1; then
  echo "[OK] git: $(git --version)"
else
  echo "[MISSING] git"
  missing+=("git")
  ok=1
fi

if [ "$ok" -ne 0 ]; then
  echo
  echo "Missing tools detected. Install with:"
  echo "  sudo apt update && sudo apt install -y ${missing[*]}"
  exit 1
fi

echo
echo "All prerequisites present."
exit 0
