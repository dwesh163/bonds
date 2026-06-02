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

SOURCE_SIZE=$(du -sh "${BACKUP_PATH}" | cut -f1)

if ! restic snapshots --quiet > /dev/null 2>&1; then
    echo "Repository not found, initializing..."
    restic init
fi

BACKUP_LOG=$(mktemp)
restic backup "${BACKUP_PATH}" --tag "${BACKUP_TAG}" --verbose > "$BACKUP_LOG" 2>&1 || { cat "$BACKUP_LOG" >&2; rm -f "$BACKUP_LOG"; exit 1; }

SNAPSHOT_ID=$(grep "snapshot .* saved" "$BACKUP_LOG" | awk '{print $2}')
FILES_NEW=$(grep "^Files:" "$BACKUP_LOG" | awk '{print $2}')
FILES_CHANGED=$(grep "^Files:" "$BACKUP_LOG" | awk '{print $4}')
FILES_UNMODIFIED=$(grep "^Files:" "$BACKUP_LOG" | awk '{print $6}')
UPLOADED=$(grep "Added to the repository:" "$BACKUP_LOG" | sed 's/.*Added to the repository: //')
DURATION=$(grep "^processed" "$BACKUP_LOG" | awk '{print $NF}')
rm -f "$BACKUP_LOG"

FORGET_LOG=$(mktemp)
restic forget --prune --tag "${BACKUP_TAG}" --keep-last "${RETENTION_KEEP_LAST}" > "$FORGET_LOG" 2>&1 || { cat "$FORGET_LOG" >&2; rm -f "$FORGET_LOG"; exit 1; }
REMOVED=$(grep "snapshots have been removed" "$FORGET_LOG" | awk '{print $1}')
REMOVED="${REMOVED:-0}"
rm -f "$FORGET_LOG"

STATS_LOG=$(mktemp)
restic stats --mode restore-size > "$STATS_LOG" 2>&1 || { cat "$STATS_LOG" >&2; rm -f "$STATS_LOG"; exit 1; }
REPO_SIZE=$(grep "Total Size:" "$STATS_LOG" | awk '{print $3, $4}')
REPO_SNAPSHOTS=$(grep "Snapshots:" "$STATS_LOG" | awk '{print $2}')
rm -f "$STATS_LOG"

echo ""
echo "==============================="
echo "  Backup complete"
echo "==============================="
printf "  Tag       : %s\n" "${BACKUP_TAG}"
printf "  Source    : %s (%s)\n" "${BACKUP_PATH}" "${SOURCE_SIZE}"
printf "  Snapshot  : %s\n" "${SNAPSHOT_ID}"
printf "  Duration  : %s\n" "${DURATION}"
echo "-------------------------------"
printf "  New files : %s\n" "${FILES_NEW}"
printf "  Changed   : %s\n" "${FILES_CHANGED}"
printf "  Unchanged : %s\n" "${FILES_UNMODIFIED}"
printf "  Uploaded  : %s\n" "${UPLOADED}"
echo "-------------------------------"
printf "  Kept      : %s snapshots\n" "${REPO_SNAPSHOTS}"
printf "  Removed   : %s snapshots\n" "${REMOVED}"
printf "  Repo size : %s\n" "${REPO_SIZE}"
echo "==============================="
