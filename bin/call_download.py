import sys
import os
import json
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

# Add `lib/python_utils` directory to Python path with an absolute path
python_utils_path = "/app/lib/python_utils"
sys.path.append(python_utils_path)

# Add debugging info
current_dir = os.path.dirname(os.path.abspath(__file__))
lib_path = os.path.join(current_dir, "../lib/python_utils")
print(f"Adding lib_path to sys.path: {lib_path}")
sys.path.append(lib_path)

# Attempt to import modules
try:
    import downloader5
    import utilities1
except ImportError as e:
    logger.error("Error: Required module not found: %s", e)
    sys.exit(1)

# Load Config
config_file = "./conf/app_config.json"

try:
    with open(config_file, "r") as file:
        config = json.load(file)
except FileNotFoundError:
    logger.error(f"Error: Configuration file '{config_file}' not found.")
    sys.exit(1)

# Correctly setting the download path
download_date = datetime.now().strftime("%Y-%m-%d")
#config["download_path"] = f"{config['target_usb_mount']}{download_date}/"
config["download_path"] = os.path.join(config["target_usb_mount"], download_date)

# Verify directory creation
logger.info(f"Verifying directory: {config['download_path']}")
if not os.path.exists(config["download_path"]):
    logger.error(f"Directory not found: {config['download_path']}")
    sys.exit(1)


# Ensure the directory for the log file exists
log_file = os.path.expanduser(config["logging"]["log_filename"])
log_dir = os.path.dirname(log_file)

if not os.path.exists(log_dir):
    try:
        os.makedirs(log_dir, exist_ok=True)
    except Exception as e:
        logger.error(f"Error creating log directory '{log_dir}': {e}")
        sys.exit(1)



# Main Function
def main():
    params = {
        "download_path": config["download_path"],
        "cookie_path": (
            config.get("cookie_path")
            if os.path.exists(os.path.expanduser(config.get("cookie_path", "")))
            else None
        ),
        "url": None,
        **config.get("watermark_config", {}),
    }

    # Check for URL in command-line arguments
    if len(sys.argv) < 2:
        logger.error(
            "The URL is missing. Please provide a valid URL as a command-line argument."
        )
        sys.exit(1)

    params["url"] = sys.argv[1].strip()

    # Function calls
    function_calls = [
        downloader5.mask_metadata,
        downloader5.create_original_filename,
        downloader5.download_video,
        utilities1.store_params_as_json,  # Adding JSON storage function call
    ]

    # Execute each function and aggressively log entry
    for func in function_calls:
        logger.info(f"Entering function: {func.__name__}")
        try:
            result = func(params)
            if result:
                params.update(result)
                # logger.info(f"Updated params after {func.__name__}: {params}")
        except Exception as e:
            logger.error(f"Error executing {func.__name__}: {e}")
            logger.debug(traceback.format_exc())
    
    # Return the original filename
    original_filename = params.get("original_filename", "")
    if original_filename:
        logger.info(f"Returning original filename: {original_filename}")
        return original_filename
    else:
        logger.warning("No original filename to return.")
        return None

if __name__ == "__main__":
    filename = main()
    if filename:
        print(f"{filename}")
    else:
        print("No filename generated.")

