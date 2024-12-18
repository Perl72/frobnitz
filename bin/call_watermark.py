# call_watermark.py


import datetime  # Correctly importing the module
import os
from moviepy.video.io.VideoFileClip import VideoFileClip
from moviepy.video.VideoClip import TextClip
from moviepy.video.compositing.CompositeVideoClip import CompositeVideoClip
import logging
import json
import sys




# Logger setup
logging.basicConfig(level=logging.DEBUG)
logger = logging.getLogger(__name__)

def get_codecs_by_extension(extension):
    """Determine codecs based on file extension."""
    codecs = {
        ".webm": {"video_codec": "libvpx", "audio_codec": "libvorbis"},
        ".mp4": {"video_codec": "libx264", "audio_codec": "aac"},
        ".ogv": {"video_codec": "libtheora", "audio_codec": "libvorbis"},
        ".mkv": {"video_codec": "libx264", "audio_codec": "aac"},
    }
    return codecs.get(extension, {"video_codec": "libx264", "audio_codec": "aac"})


def add_watermark(params):
    """
    Adds watermark text overlays to a video file.

    Args:
        params (dict): Parameters for adding watermark, including:
            - input_video_path (str): Path to the input video.
            - download_path (str): Directory to save the watermarked video.
            - username (str): Username to add as a watermark.
            - video_date (str): Date to add as a watermark.
            - font (str): Font type for watermark text.
            - font_size (int): Font size for watermark text.
            - username_color (str): Color of the username watermark text.
            - date_color (str): Color of the date watermark text.
            - timestamp_color (str): Color of the timestamp watermark text.
            - username_position (tuple): Position for username watermark.
            - date_position (tuple): Position for date watermark.
            - timestamp_position (tuple): Position for timestamp watermark.

    Returns:
        dict: A dictionary with the path to the watermarked video under 'to_process',
              or None if an error occurs.
    """
    # Print incoming parameters for diagnostics
    logger.debug("Received parameters:")
    for key, value in params.items():
        logger.debug(f"{key}: {value}")

    input_video_path = params.get("input_video_path")  # Use standardized key
    logger.debug(f"Using input_video_path: {input_video_path}")
    if not input_video_path:
        raise ValueError("Missing required parameter: 'input_video_path'")

    download_path = params.get("download_path")
    username = params.get("username", "Little Timmy")
    video_date = params.get("video_date", "Date")
    font = params.get("font", "Arial-Bold")
    font_size = params.get("font_size", 48)
    username_color = params.get("username_color", "yellow")
    date_color = params.get("date_color", "cyan")
    timestamp_color = params.get("timestamp_color", "red")
    username_position = params.get("username_position", ("left", "top"))
    date_position = params.get("date_position", ("left", "bottom"))
    timestamp_position = params.get("timestamp_position", ("right", "bottom"))

    try:
        # Load the video file
        video = VideoFileClip(input_video_path)

        # Create watermark text clips
        username_clip = (
            TextClip(username, fontsize=font_size, color=username_color, font=font)
            .set_position(username_position)
            .set_duration(video.duration)
        )

        date_clip = (
            TextClip(video_date, fontsize=font_size, color=date_color, font=font)
            .set_position(date_position)
            .set_duration(video.duration)
        )

        # Add timestamp for each second
        timestamp_clips = []
        for t in range(int(video.duration)):
            timestamp = f"{t // 3600:02}:{(t % 3600) // 60:02}:{t % 60:02}"
            timestamp_clip = (
                TextClip(
                    timestamp, fontsize=font_size, color=timestamp_color, font=font
                )
                .set_position(timestamp_position)
                .set_start(t)
                .set_duration(1)
            )
            timestamp_clips.append(timestamp_clip)

        # Combine everything into one final video, including the original audio
        final = CompositeVideoClip([video, username_clip, date_clip] + timestamp_clips)

        # Make sure to include audio
        final = final.set_audio(video.audio)

        # Generate the watermarked video path
        filename, ext = os.path.splitext(os.path.basename(input_video_path))
        watermarked_video_path = os.path.join(
            download_path, f"{filename}_watermarked{ext}"
        )

        # Set appropriate codec and audio codec based on file extension
        codecs = get_codecs_by_extension(ext)
        video_codec = codecs["video_codec"]
        audio_codec = codecs["audio_codec"]

        # Export the video with sound
        final.write_videofile(
            watermarked_video_path, codec=video_codec, audio_codec=audio_codec
        )
        logger.info(f"Watermarked video saved to: {watermarked_video_path}")
        params["to_process"] = watermarked_video_path  # Update to_process after

        return {"to_process": watermarked_video_path}

    except Exception as e:
        logger.error(f"Error in adding watermark: {e}")
        return None


if __name__ == "__main__":
    # Prepare the parameters from the configuration or command-line arguments
    config_file = "./conf/app_config.json"
    try:
        with open(config_file, "r") as file:
            config = json.load(file)
    except FileNotFoundError:
        logger.error(f"Error: Configuration file '{config_file}' not found.")
        sys.exit(1)

    # Prepare parameters for watermarking
    params = {
        "input_video_path": sys.argv[1] if len(sys.argv) > 1 else config.get("input_video_path"),
        "download_path": config.get("download_path", "/tmp/"),
        "username": config.get("user_id", "DefaultUser"),
        "video_date": datetime.datetime.now().strftime("%Y-%m-%d"),
        "font": config.get("watermark_config", {}).get("font", "Arial-Bold"),
        "font_size": config.get("watermark_config", {}).get("font_size", 48),
        "username_color": config.get("watermark_config", {}).get("username_color", "yellow"),
        "date_color": config.get("watermark_config", {}).get("date_color", "cyan"),
        "timestamp_color": config.get("watermark_config", {}).get("timestamp_color", "red"),
        "username_position": tuple(config.get("watermark_config", {}).get("username_position", ["left", "top"])),
        "date_position": tuple(config.get("watermark_config", {}).get("date_position", ["left", "bottom"])),
        "timestamp_position": tuple(config.get("watermark_config", {}).get("timestamp_position", ["right", "bottom"])),
    }

    # Call the watermarking function
    try:
        logger.info("Starting watermarking process...")
        result = add_watermark(params)
        if result and "to_process" in result:
            logger.info(f"Watermarked video created: {result['to_process']}")
            print(result["to_process"])  # Print the output filename
        else:
            logger.error("Watermarking failed or did not return a valid output.")
            sys.exit(1)
    except Exception as e:
        logger.error(f"An error occurred during the watermarking process: {e}")
        logger.debug(traceback.format_exc())
        sys.exit(1)

