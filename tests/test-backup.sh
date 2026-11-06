#!/usr/bin/env bash
set -Eeuo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Create an isolated test environment.
TEST_DIR="$(mktemp -d)"
trap 'rm -rf -- "$TEST_DIR"' EXIT

mkdir -p "$TEST_DIR/source" "$TEST_DIR/destination" "$TEST_DIR/logs"

# Use an isolated rclone configuration.
export RCLONE_CONFIG="$TEST_DIR/rclone.conf"
export CONFIG_FILE="$TEST_DIR/config.conf"

cat > "$CONFIG_FILE" <<CONFIG
SOURCE_DIR="$TEST_DIR/source"
DEST_REMOTE="testremote"
DEST_PATH="Projects"
VERSIONS_PATH="Versions"
LOG_DIR="$TEST_DIR/logs"
TRANSFERS=1
CONFIG

rclone config create testremote alias \
    remote "$TEST_DIR/destination" >/dev/null

printf 'Original backup data\n' > "$TEST_DIR/source/test.txt"

echo "TEST 1: Initial backup"
"$PROJECT_DIR/scripts/backup.sh" --run

echo "TEST 2: Full verification"
"$PROJECT_DIR/scripts/verify.sh" --full

echo "TEST 3: Detect corruption"
printf 'Corrupted backup\n' > "$TEST_DIR/destination/Projects/test.txt"

if "$PROJECT_DIR/scripts/verify.sh" --full; then
    echo "FAIL: Corruption was not detected." >&2
    exit 1
fi

echo "TEST 4: Repair backup"
"$PROJECT_DIR/scripts/backup.sh" --run
"$PROJECT_DIR/scripts/verify.sh" --full

echo "TEST 5: Confirm version history"
if [[ ! -n "$(rclone lsf testremote:Versions --recursive)" ]]; then
    echo "FAIL: No version history found." >&2
    exit 1
fi

echo "ALL TESTS PASSED"
