#!/usr/bin/env bash
# Archive stateful Docker volumes into timestamped tarballs under backups/.
# Usage: ./scripts/backup-volumes.sh [--dry-run]
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BACKUP_DIR="$REPO_ROOT/backups"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
DRY_RUN=0
[[ "${1:-}" == "--dry-run" ]] && DRY_RUN=1

# Named volumes to back up (compose project prefix_volume name).
# The infrastructure stack uses "infrastructure" as the Compose project name.
VOLUMES=(
  "infrastructure_minio_data"
  "infrastructure_grafana_data"
  "infrastructure_prometheus_data"
  "infrastructure_loki_data"
  "infrastructure_portainer_data"
  "infrastructure_letsencrypt"
)

mkdir -p "$BACKUP_DIR"
echo "==> Backup directory: $BACKUP_DIR"
echo "==> Timestamp: $TIMESTAMP"
echo ""

for vol in "${VOLUMES[@]}"; do
  archive="${BACKUP_DIR}/${vol}_${TIMESTAMP}.tar.gz"

  # Skip volumes that don't exist yet (e.g. stack never started)
  if ! docker volume inspect "$vol" &>/dev/null; then
    echo "  SKIP $vol (volume not found)"
    continue
  fi

  echo "  → $vol"
  if [[ "$DRY_RUN" -eq 0 ]]; then
    docker run --rm \
      -v "${vol}:/data:ro" \
      -v "${BACKUP_DIR}:/backup" \
      alpine:3.22 \
      tar czf "/backup/$(basename "$archive")" -C /data .
    size=$(du -sh "$archive" | cut -f1)
    echo "    saved: $(basename "$archive") ($size)"
  else
    echo "    (dry-run) would write: $(basename "$archive")"
  fi
done

echo ""
if [[ "$DRY_RUN" -eq 0 ]]; then
  count=$(find "$BACKUP_DIR" -maxdepth 1 -name "*.tar.gz" | wc -l)
  echo "==> Done. $count archive(s) total in $BACKUP_DIR"
else
  echo "==> Dry run complete — no files written."
fi
