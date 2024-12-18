import os
from moviepy.video.io.VideoFileClip import VideoFileClip
from moviepy.video.VideoClip import TextClip
from moviepy.video.compositing.CompositeVideoClip import CompositeVideoClip
import logging
import datetime

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

    try:
        # Log before loading the video file
        logger.debug(f"About to load video file from: {input_video_path}")
        video = VideoFileClip(input_video_path)

        # Log before creating watermark text clips
        logger.debug(f"Creating watermark text clips for: {input_video_path}")
        username_clip = (
            TextClip(params["username"], fontsize=params["font_size"], color=params["username_color"], font=params["font"])
            .set_position(params["username_position"])
            .set_duration(video.duration)
        )
        date_clip = (
            TextClip(params["video_date"], fontsize=params["font_size"], color=params["date_color"], font=params["font"])
            .set_position(params["date_position"])
            .set_duration(video.duration)
        )

        # Log before adding timestamp clips
        logger.debug(f"Adding timestamp clips for video: {input_video_path}")
        timestamp_clips = []
        for t in range(int(video.duration)):
            timestamp = f"{t // 3600:02}:{(t % 3600) // 60:02}:{t % 60:02}"
            timestamp_clip = (
                TextClip(
                    timestamp, fontsize=params["font_size"], color=params["timestamp_color"], font=params["font"]
                )
                .set_position(params["timestamp_position"])
                .set_start(t)
                .set_duration(1)
            )
            timestamp_clips.append(timestamp_clip)

        # Log before combining all clips
        logger.debug(f"Combining clips for final video: {input_video_path}")
        final = CompositeVideoClip([video, username_clip, date_clip] + timestamp_clips)

        # Log before setting audio
        logger.debug(f"Setting audio for video: {input_video_path}")
        final = final.set_audio(video.audio)

        # Generate the watermarked video path
        filename, ext = os.path.splitext(os.path.basename(input_video_path))
        watermarked_video_path = os.path.join(params["download_path"], f"{filename}_watermarked{ext}")
        logger.debug(f"Watermarked video path: {watermarked_video_path}")

        # Set appropriate codec and audio codec based on file extension
        codecs = get_codecs_by_extension(ext)
        video_codec = codecs["video_codec"]
        audio_codec = codecs["audio_codec"]

        # Log before exporting video
        logger.debug(f"Exporting watermarked video to: {watermarked_video_path}")
        final.write_videofile(watermarked_video_path, codec=video_codec, audio_codec=audio_codec)

        logger.debug(f"Watermarked video saved to: {watermarked_video_path}")
        params["to_process"] = watermarked_video_path  # Update to_process after

        return {"to_process": watermarked_video_path}

    except Exception as e:
        logger.error(f"Error in adding watermark: {e}")
        logger.debug(traceback.format_exc())
        return None


if __name__ == "__main__":


