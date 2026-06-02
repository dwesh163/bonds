#!/bin/sh
set -e

BACKUP_PATH="${BACKUP_PATH:-/data}"
BACKUP_TAG="${BACKUP_TAG:-bonds}"
RETENTION_KEEP_LAST="${RETENTION_KEEP_LAST:-7}"

error=0
for var in RESTIC_REPOSITORY RESTIC_PASSWORD AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY; do
    eval "val=\$$var"
    if [ -z "$val" ]; then
        echo "ERROR: $var is required" >&2
        error=1
    fi
done
[ "$error" -eq 1 ] && exit 1

if [ ! -d "$BACKUP_PATH" ]; then
    echo "ERROR: BACKUP_PATH '$BACKUP_PATH' does not exist or is not a directory" >&2
    exit 1
fi

echo "Starting backup of ${BACKUP_PATH} (tag: ${BACKUP_TAG})"

if ! restic snapshots --quiet > /dev/null 2>&1; then
    echo "Repository not found, initializing..."
    restic init
fi

echo "Running backup..."
restic backup "${BACKUP_PATH}" --tag "${BACKUP_TAG}" --verbose

echo "Pruning old snapshots (keep last ${RETENTION_KEEP_LAST})..."
restic forget --prune --tag "${BACKUP_TAG}" --keep-last "${RETENTION_KEEP_LAST}"

echo "Repository stats..."
restic stats --mode restore-size
