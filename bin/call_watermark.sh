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

# Parse config using jq
usb_mount_name=$(jq -r '.target_usb_mount' "$Config_Path" | sed 's:/$::')
log_message "Target USB mount name from config: $usb_mount_name"

# Locate the USB volume dynamically
if [[ "$OS_TYPE" == "Darwin" ]]; then
    usb_mount_point=$(ls /Volumes | grep -i "$usb_mount_name" | head -n 1)
    if [ -z "$usb_mount_point" ]; then
        log_message "Error: Unable to locate the volume '$usb_mount_name'. Available volumes: $(ls /Volumes)"
        exit 1
    fi
    usb_mount_point="/Volumes/$usb_mount_point"
else
    usb_mount_point="/media/$USER/$usb_mount_name"
fi

log_message "Detected USB mount point: $usb_mount_point"

# Validate USB mount
if [ ! -d "$usb_mount_point" ]; then
    log_message "Error: Volume '$usb_mount_point' is not mounted. Please mount the volume and try again."
    exit 1
fi

# Create watermark directory
watermark_date=$(date +%Y-%m-%d)
watermark_path="$usb_mount_point/$watermark_date/"
log_message "Attempting to create directory: $watermark_path"
mkdir -p "$watermark_path" || { log_message "Error creating watermark directory: $watermark_path"; exit 1; }
log_message "Directory created or already exists: $watermark_path"

# Check if the Docker image exists
if [[ "$(docker images -q my_dl:latest 2> /dev/null)" == "" ]]; then
    log_message "Docker image 'my_dl:latest' does not exist. Building the image..."
    docker build -f "$SCRIPT_DIR/../Dockerfile" -t my_dl "$SCRIPT_DIR/.."
else
    log_message "Docker image 'my_dl:latest' found."
fi

# Run Docker to add the watermark
log_message "Running Docker to add watermark..."
watermarked_filename=$(docker run --rm \
  -e PYTHONPATH="/app/lib/python_utils:/app/lib" \
  -v "$Config_Path":/app/conf/app_config.json \
  -v "$usb_mount_point":"$usb_mount_point" \
  my_dl:latest python3 /app/bin/call_watermark.py "$1" | tail -n 1)


# Remove trailing whitespace or newlines
watermarked_filename=$(echo "$watermarked_filename" | sed 's/\s*$//')

# Sleep to allow for any file system updates
sleep 1

# Validate the watermarked filename
if [ -z "$watermarked_filename" ] || [[ "$watermarked_filename" == *"Error"* ]]; then
  log_message "Error: watermarked_filename is not set or invalid."
  exit 1
fi

# Log success
log_message "File validation successful: $watermarked_filename"

exit 0

