#!/bin/sh
set -e

BACKUP_PATH="${BACKUP_PATH:-/data}"
BACKUP_TAG="${BACKUP_TAG:-bonds}"
RETENTION_KEEP_LAST="${RETENTION_KEEP_LAST:-7}"

: "${RESTIC_REPOSITORY:?RESTIC_REPOSITORY is required}"
: "${RESTIC_PASSWORD:?RESTIC_PASSWORD is required}"
: "${AWS_ACCESS_KEY_ID:?AWS_ACCESS_KEY_ID is required}"
: "${AWS_SECRET_ACCESS_KEY:?AWS_SECRET_ACCESS_KEY is required}"

echo "[bonds] Starting backup of ${BACKUP_PATH} to ${RESTIC_REPOSITORY}"

if ! restic snapshots --quiet > /dev/null 2>&1; then
    echo "[bonds] Repository not found, initializing..."
    restic init
fi

echo "[bonds] Running backup..."
restic backup "${BACKUP_PATH}" --tag "${BACKUP_TAG}"

echo "[bonds] Pruning snapshots (keep-last=${RETENTION_KEEP_LAST})..."
restic forget --prune \
    --tag "${BACKUP_TAG}" \
    --keep-last "${RETENTION_KEEP_LAST}"

echo "[bonds] Backup complete."
