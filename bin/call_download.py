import sys
import os
import json
import glob
import logging
import traceback
from datetime import datetime

# Logger setup - Single Setup for Console and File Logging
logger = logging.getLogger(__name__)
logger.setLevel(logging.DEBUG)  # Set to DEBUG to capture all logs

# Console handler for logging
console_handler = logging.StreamHandler(stream=sys.stderr)  # Send logs to stderr
console_handler.setLevel(logging.INFO)
formatter = logging.Formatter("%(asctime)s - %(name)s - %(levelname)s - %(message)s")
console_handler.setFormatter(formatter)
logger.addHandler(console_handler)

# Resolve paths from this file, so the script works from any working directory
current_dir = os.path.dirname(os.path.abspath(__file__))
repo_root = os.path.dirname(current_dir)
lib_path = os.path.join(repo_root, "lib", "python_utils")
if lib_path not in sys.path:
    sys.path.insert(0, lib_path)

# Attempt to import modules
try:
    import downloader5
    import utilities1
except ImportError as e:
    logger.error("Error: Required module not found: %s", e)
    sys.exit(1)

# Load Config
config_file = os.environ.get(
    "FROBNITZ_CONFIG", os.path.join(repo_root, "conf", "app_config.json")
)

try:
    with open(config_file, "r") as file:
        config = json.load(file)
except FileNotFoundError:
    logger.error(f"Error: Configuration file '{config_file}' not found.")
    sys.exit(1)

# Download root: env override, then config target, then a repo-local data/ dir
download_date = datetime.now().strftime("%Y-%m-%d")
download_root = (
    os.environ.get("FROBNITZ_DOWNLOAD_ROOT")
    or config.get("target_usb_mount")
    or os.path.join(repo_root, "data")
)
download_path = os.path.abspath(os.path.join(download_root, download_date))
config["download_path"] = download_path

# Ensure the directory for the log file exists (relative paths resolve to the repo)
log_file = os.path.expanduser(config.get("logging", {}).get("log_filename", "./dl.log"))
if not os.path.isabs(log_file):
    log_file = os.path.join(repo_root, log_file)
log_dir = os.path.dirname(log_file)

if not os.path.exists(log_dir):
    try:
        os.makedirs(log_dir, exist_ok=True)
    except Exception as e:
        logger.error(f"Error creating log directory '{log_dir}': {e}")
        sys.exit(1)

# Ensure the download directory exists; fall back to the repo data/ dir if not
try:
    os.makedirs(download_path, exist_ok=True)
    logger.info(f"Download directory created or exists: {download_path}")
except Exception as e:
    fallback_path = os.path.abspath(os.path.join(repo_root, "data", download_date))
    logger.warning(
        f"Cannot use download root '{download_root}' ({e}); falling back to {fallback_path}"
    )
    os.makedirs(fallback_path, exist_ok=True)
    download_path = fallback_path
    config["download_path"] = download_path

# Main Function
def main():
    video_download = dict(config.get("video_download", {}))
    cookie_path = config.get("cookie_path") or video_download.get("cookie_path")
    if cookie_path and not os.path.exists(os.path.expanduser(cookie_path)):
        cookie_path = None
    video_download["cookie_path"] = cookie_path

    params = {
        "download_path": config["download_path"],
        "cookie_path": cookie_path,
        "video_download": video_download,
        "logging": config.get("logging", {}),
        "url": None,
        **config.get("watermark_config", {}),
    }

    # Check for URL in command-line arguments
    if len(sys.argv) < 2:
        logger.error("The URL is missing. Please provide a valid URL as a command-line argument.")
        sys.exit(1)

    params["url"] = sys.argv[1].strip()

    # Execute functions
    function_calls = [
        downloader5.mask_metadata,
        downloader5.create_original_filename,
        downloader5.download_video,
        utilities1.store_params_as_json,
    ]

    for func in function_calls:
        logger.info(f"Entering function: {func.__name__}")
        try:
            result = func(params)
            if result:
                params.update(result)
        except Exception as e:
            logger.error(f"Error executing {func.__name__}: {e}")
            logger.debug(traceback.format_exc())

    # Return the filename of the file that actually exists on disk
    original_filename = params.get("original_filename", "")
    if original_filename and not os.path.exists(original_filename):
        base = os.path.splitext(original_filename)[0]
        matches = [
            p
            for p in glob.glob(base + ".*")
            if not p.endswith((".part", ".ytdl", ".json"))
        ]
        if matches:
            original_filename = max(matches, key=os.path.getmtime)
            params["original_filename"] = original_filename

    if original_filename and os.path.exists(original_filename):
        logger.info(f"Returning original filename: {original_filename}")
        print(original_filename)  # Output only the original filename
        return original_filename

    logger.warning("No downloaded file to return.")
    return None

if __name__ == "__main__":
    main()
