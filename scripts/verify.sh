#!/usr/bin/env bash
set -Eeuo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CONFIG_FILE="${CONFIG_FILE:-$PROJECT_DIR/config.conf}"

if [[ ! -f "$CONFIG_FILE" ]]; then
    echo "ERROR: Configuration not found: $CONFIG_FILE" >&2
    exit 1
fi

# Only load trusted configuration files.
source "$CONFIG_FILE"

: "${SOURCE_DIR:?SOURCE_DIR is required}"
: "${DEST_REMOTE:?DEST_REMOTE is required}"
: "${DEST_PATH:?DEST_PATH is required}"

if ! command -v rclone >/dev/null 2>&1; then
    echo "ERROR: rclone is not installed." >&2
    exit 1
fi

if [[ ! -d "$SOURCE_DIR" ]]; then
    echo "ERROR: Source directory does not exist." >&2
    exit 1
fi

DEST="${DEST_REMOTE}:${DEST_PATH}"
MODE="${1:---quick}"

case "$MODE" in
    --quick)
        echo "Running standard rclone verification..."
        rclone check "$SOURCE_DIR" "$DEST" --progress
        ;;
    --full)
        echo "Running full downloaded-content verification..."
        rclone check "$SOURCE_DIR" "$DEST" \
            --download \
            --transfers "${TRANSFERS:-1}" \
            --progress
        ;;
    *)
        echo "Usage: $0 [--quick|--full]" >&2
        exit 1
        ;;
esac

echo "Backup verification PASSED."
