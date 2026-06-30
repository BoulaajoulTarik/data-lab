# Volume Backups

All persistence in this lab lives in named Docker volumes. The backup script archives them
into timestamped tarballs using a short-lived Alpine container — no stack shutdown required.

## Volumes covered

| Volume | Contents |
|---|---|
| `infrastructure_minio_data` | MinIO object store (Parquet files, demo-data bucket) |
| `infrastructure_grafana_data` | Grafana dashboards, users, datasource state |
| `infrastructure_prometheus_data` | Prometheus TSDB (15-day retention) |
| `infrastructure_loki_data` | Loki log store |
| `infrastructure_portainer_data` | Portainer configuration |
| `infrastructure_letsencrypt` | Let's Encrypt certificates (`acme.json`) |

## Taking a backup

```bash
# From repo root (local or VPS — docker must be running)
make backup
# or directly:
./scripts/backup-volumes.sh
```

Archives land in `backups/` (gitignored) as:
```
backups/<volume>_<YYYYMMDD_HHMMSS>.tar.gz
```

For a dry run (list what would be backed up without writing files):
```bash
./scripts/backup-volumes.sh --dry-run
```

## Restoring a volume

Restoring overwrites the volume — stop any containers using it first.

```bash
# 1. Stop the stack
docker compose -f infrastructure/docker-compose.yml down

# 2. (Optional) remove the existing volume to start clean
docker volume rm infrastructure_<name>

# 3. Restore from archive
docker run --rm \
  -v "infrastructure_<name>:/data" \
  -v "$(pwd)/backups:/backup:ro" \
  alpine:3.22 \
  tar xzf /backup/<archive>.tar.gz -C /data

# 4. Restart the stack
docker compose -f infrastructure/docker-compose.yml up -d
```

## Off-box copy (recommended)

The `backups/` directory lives on the VPS. For real safety, copy archives off-box:

```bash
# From local machine — pull latest archives from VPS
rsync -av -e "ssh -i ~/.ssh/data-lab-deploy" \
  deploy@167.233.138.193:~/data-lab/backups/ \
  ./backups/
```

## Retention

The backup script adds archives but never removes old ones. Prune manually when disk fills:

```bash
# Remove archives older than 7 days
find backups/ -name "*.tar.gz" -mtime +7 -delete
```
