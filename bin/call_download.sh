#!/bin/bash
set -x

# Get the directory of the current script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Define local log directory and log file path
LOCAL_LOG_DIR="$SCRIPT_DIR/../logs"
LOCAL_LOG_FILE="$LOCAL_LOG_DIR/bash_wrapper.log"

# Ensure the local log directory exists
mkdir -p "$LOCAL_LOG_DIR" || { echo "Error creating log directory: $LOCAL_LOG_DIR"; exit 1; }

# Function to log messages
log_message() {
    echo "$(date +'%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOCAL_LOG_FILE"
}

# Detect the operating system
OS_TYPE=$(uname)
log_message "Detected OS: $OS_TYPE"

# Function to start Docker if it's not running
start_docker() {
    log_message "Ensuring Docker is running..."
    if [[ "$OS_TYPE" == "Linux" ]]; then
        # Linux-specific logic
        if ! systemctl is-active --quiet docker; then
            log_message "Docker is not running. Starting Docker..."
            sudo systemctl start docker
            if [ $? -ne 0 ]; then
                log_message "Error: Failed to start Docker. Please start it manually."
                exit 1
            fi
        else
            log_message "Docker is already running."
        fi
    elif [[ "$OS_TYPE" == "Darwin" ]]; then
        # macOS-specific logic
        if ! pgrep -f "Docker.app" >/dev/null; then
            log_message "Docker is not running. Attempting to start Docker..."
            open -a Docker
            log_message "Waiting for Docker to start..."
            while ! docker info >/dev/null 2>&1; do
                sleep 1
            done
            log_message "Docker started successfully."
        else
            log_message "Docker is already running."
        fi
    else
        log_message "Unsupported operating system: $OS_TYPE"
        exit 1
    fi
}

# Start Docker
start_docker

# Load Configuration
Config_Path="$SCRIPT_DIR/../conf/app_config.json"
log_message "Loading configuration from $Config_Path..."
if [ ! -f "$Config_Path" ]; then
    log_message "Error: Config file '$Config_Path' not found. Please verify the path and try again."
    exit 1
fi

# Check if the Docker image exists
if [[ "$(docker images -q my_dl:latest 2> /dev/null)" == "" ]]; then
    log_message "Docker image 'my_dl:latest' does not exist. Building the image..."
    docker build -f "$SCRIPT_DIR/../Dockerfile" -t my_dl "$SCRIPT_DIR/.."
else
    log_message "Docker image 'my_dl:latest' found."
fi

echo "DOCKER"
# Run Docker to download the video
log_message "Running Docker with the specified volume and config path..."
original_filename=$(docker run --rm \
  -e PYTHONPATH="/app/lib/python_utils:/app/lib" \
  -v "$Config_Path":/app/conf/app_config.json \
  -v "$usb_mount_point":"$usb_mount_point" \
  my_dl python3 /app/bin/call_download.py "$1" 2>stderr.log | tail -n 1)

# Trim any extra whitespace or newlines
original_filename=$(echo "$original_filename" | sed 's/^\s*//;s/\s*$//')

# Debug: Log outputs
log_message "Captured Docker stdout: $original_filename"
log_message "Captured Docker stderr: $(cat stderr.log)"

# Sleep to allow file system updates (if needed)
sleep 3

# Validate the original filename
if [ -z "$original_filename" ] || [[ "$original_filename" == *"Error"* ]]; then
  log_message "Error: original_filename is not set or invalid."
  exit 1
fi

# Print only the filename as the final output
echo "$original_filename"

