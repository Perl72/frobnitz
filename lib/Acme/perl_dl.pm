# Download a video using yt-dlp
sub download_video {
    my ($self, $url, $output_dir) = @_;

    # Validate inputs
    croak "URL not provided!" unless $url;

    # Set default output directory
    $output_dir ||= "./videos";

    # Create output directory if it doesn't exist
    mkdir $output_dir unless -d $output_dir;

    # Generate a unique filename for the download
    my $output_file = "$output_dir/downloaded_video.mp4"; # Replace this with unique logic if needed

    # Download the video
    print "Downloading video from: $url\n";
    my $download_command = qq(
        yt-dlp -o "$output_file" "$url"
    );

    system($download_command) == 0
        or croak "Failed to download video: $!";

    return $output_file;
}

# Add watermark to a video
sub add_watermark {
    my ($self, $input_file, $output_dir, $watermark_text) = @_;

    # Validate inputs
    croak "Input file not provided!" unless $input_file;
    croak "File does not exist: $input_file" unless -e $input_file;

    # Set default output directory and watermark text
    $output_dir ||= "./watermarked_videos";
    $watermark_text ||= "Watermark";

    # Generate output filename
    my ($basename, $dirname, $ext) = fileparse($input_file, qr/\.[^.]*/);
    my $output_file = "$output_dir/${basename}_watermarked$ext";

    # Build the FFmpeg command
    my $ffmpeg_command = qq(
        ffmpeg -i "$input_file" -vf "drawtext=text='$watermark_text':fontcolor=white:fontsize=24:x=(w-text_w)/2:y=(h-text_h)/2" -codec:a copy "$output_file"
    );

    # Execute the FFmpeg command
    system($ffmpeg_command) == 0
        or croak "Failed to execute FFmpeg command: $!";

    return $output_file;
}

