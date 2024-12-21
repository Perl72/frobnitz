use strict;
use warnings;
use Acme::Frobnitz;

# Instantiate the Frobnitz object
my $frobnitz = Acme::Frobnitz->new();

# URL of the video to download
my $video_url = "https://www.instagram.com/p/DDa_FxsNtTe/";

# Step 1: Download the video
print "Starting download for URL: $video_url\n";
my $download_output = $frobnitz->download($video_url);

# Extract the last line of the output
my @output_lines = split(/\n/, $download_output);  # Split output into lines
my $last_line = $output_lines[-1];                # Get the last line

# Chomp the last line to clean it up
chomp($last_line);

print "HEY: $last_line\n";
print "Downloaded video to: $last_line\n";

# Step 2: Verify the downloaded file
print "Verifying downloaded file...\n";
if ($frobnitz->verify_file($last_line)) {
    print "File verification successful.\n";
} else {
    die "File verification failed. Aborting further processing.\n";
}

# Step 3: Add watermark to the downloaded video
print "Adding watermark to: $last_line\n";
my $final_file = $frobnitz->add_watermark($last_line);

# Handle the final filename
chomp($final_file);
print "Final watermarked video is at: $final_file\n";

