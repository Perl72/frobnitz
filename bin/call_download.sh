#!/bin/bash
set -uo pipefail

# Resolve the repo root from this script's location
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# Local log file
LOCAL_LOG_DIR="$REPO_DIR/logs"
LOCAL_LOG_FILE="$LOCAL_LOG_DIR/bash_wrapper.log"
mkdir -p "$LOCAL_LOG_DIR" || { echo "Error creating log directory: $LOCAL_LOG_DIR" >&2; exit 1; }

# Log to the file and to stderr only (stdout is reserved for the filename)
log_message() {
    echo "$(date +'%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOCAL_LOG_FILE" >&2
}

if [ "$#" -lt 1 ]; then
    log_message "Error: no URL provided."
    exit 2
fi

Config_Path="${FROBNITZ_CONFIG:-$REPO_DIR/conf/app_config.json}"
log_message "Loading configuration from $Config_Path..."
if [ ! -f "$Config_Path" ]; then
    log_message "Error: Config file '$Config_Path' not found. Please verify the path and try again."
    exit 1
fi

# Docker is optional. Set FROBNITZ_USE_DOCKER=1 to use the container path.
if [ "${FROBNITZ_USE_DOCKER:-0}" = "1" ] && command -v docker >/dev/null 2>&1 && docker info >/dev/null 2>&1; then
    log_message "Using Docker."
    if [ -z "$(docker images -q my_dl:latest 2>/dev/null)" ]; then
        log_message "Docker image 'my_dl:latest' does not exist. Building the image..."
        docker build -f "$REPO_DIR/Dockerfile" -t my_dl "$REPO_DIR" || { log_message "Docker build failed."; exit 1; }
    fi
    log_message "Running Docker with the specified volume and config path..."
    docker run --rm \
      -e PYTHONPATH="/app/lib/python_utils:/app/lib" \
      -e FROBNITZ_CONFIG=/app/conf/app_config.json \
      -e FROBNITZ_DOWNLOAD_ROOT=/data \
      -v "$Config_Path":/app/conf/app_config.json:ro \
      -v "${FROBNITZ_DOWNLOAD_ROOT:-$HOME}":/data \
      my_dl python3 /app/bin/call_download.py "$1"
    exit $?
fi

# Native fallback: run the Python downloader directly (no daemon needed).
PY="${FROBNITZ_PYTHON:-}"
if [ -z "$PY" ] && [ -x "$HOME/.venvs/frobnitz/bin/python" ]; then
    PY="$HOME/.venvs/frobnitz/bin/python"
fi
PY="${PY:-python3}"
log_message "Using native Python: $PY"

cd "$REPO_DIR" || exit 1
export PYTHONPATH="$REPO_DIR/lib/python_utils:$REPO_DIR/lib${PYTHONPATH:+:$PYTHONPATH}"
exec "$PY" "$REPO_DIR/bin/call_download.py" "$1"
