#!/usr/bin/env bash
set -Eeuo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CONFIG_FILE="${CONFIG_FILE:-$PROJECT_DIR/config.conf}"

if [[ ! -f "$CONFIG_FILE" ]]; then
    echo "ERROR: Configuration not found: $CONFIG_FILE" >&2
    echo "Copy config.example.conf to config.conf and customize it."
    exit 1
fi

# Load user configuration
# Only use configuration files you trust.
source "$CONFIG_FILE"

for cmd in rclone flock; do
    command -v "$cmd" >/dev/null 2>&1 || {
        echo "ERROR: Missing dependency: $cmd" >&2
        exit 1
    }
done

: "${SOURCE_DIR:?SOURCE_DIR is required}"
: "${DEST_REMOTE:?DEST_REMOTE is required}"
: "${DEST_PATH:?DEST_PATH is required}"
: "${VERSIONS_PATH:?VERSIONS_PATH is required}"
: "${LOG_DIR:?LOG_DIR is required}"

if [[ ! -d "$SOURCE_DIR" ]]; then
    echo "ERROR: Source directory does not exist: $SOURCE_DIR" >&2
    exit 1
fi

if [[ ! "$DEST_REMOTE" =~ ^[A-Za-z0-9_-]+$ ]]; then
    echo "ERROR: Invalid remote name." >&2
    exit 1
fi

for path in "$DEST_PATH" "$VERSIONS_PATH"; do
    if [[ -z "$path" || "$path" == /* || "$path" == *..* || "$path" == *:* ]]; then
        echo "ERROR: Unsafe destination path: $path" >&2
        exit 1
    fi
done

if [[ "$DEST_PATH" == "$VERSIONS_PATH" ||
      "$DEST_PATH" == "$VERSIONS_PATH/"* ||
      "$VERSIONS_PATH" == "$DEST_PATH/"* ]]; then
    echo "ERROR: Backup and version directories must be separate." >&2
    exit 1
fi

TRANSFERS="${TRANSFERS:-1}"

if [[ ! "$TRANSFERS" =~ ^[1-9][0-9]*$ ]]; then
    echo "ERROR: TRANSFERS must be a positive integer." >&2
    exit 1
fi

DRY_RUN=false

case "${1:---dry-run}" in
    --dry-run) DRY_RUN=true ;;
    --run) DRY_RUN=false ;;
    *)
        echo "Usage: $0 [--dry-run|--run]" >&2
        exit 1
        ;;
esac

DEST="${DEST_REMOTE}:${DEST_PATH}"
VERSIONS="${DEST_REMOTE}:${VERSIONS_PATH}/$(date +%Y%m%d-%H%M%S)"

mkdir -p "$LOG_DIR"
chmod 700 "$LOG_DIR"

exec 9>"$LOG_DIR/backup.lock"
flock -n 9 || {
    echo "ERROR: Another backup is already running." >&2
    exit 1
}

LOG_FILE="$LOG_DIR/backup-$(date +%Y%m%d-%H%M%S).log"

echo "Source: $SOURCE_DIR"
echo "Destination: $DEST"
echo "Versions: $VERSIONS"
echo "Dry run: $DRY_RUN"

if [[ "$DRY_RUN" == true ]]; then
    echo "DRY RUN: No files will be transferred."
else
    echo "LIVE BACKUP: Changes will be written to the destination."
fi

ARGS=(
    copy "$SOURCE_DIR" "$DEST"
    --backup-dir "$VERSIONS"
    --transfers "$TRANSFERS"
    --log-file "$LOG_FILE"
    --log-level INFO
    --stats 30s
)

if [[ "$DRY_RUN" == true ]]; then
    ARGS+=(--dry-run)
fi

rclone "${ARGS[@]}"

echo "Backup operation completed successfully."
