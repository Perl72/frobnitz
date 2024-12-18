use strict;
use warnings;
use Acme::Frobnitz;

my $frobnitz = Acme::Frobnitz->new();

# URL of the video to download
my $video_url = "https://www.instagram.com/p/DDa_FxsNtTe/";

# Step 1: Download the video
my $downloaded_file = $frobnitz->download($video_url);

print "HEY: $downloaded_file\n";

chomp(my $chomped_filename = $downloaded_file);
print "Downloaded video to: $chomped_filename\n";

# Step 2: Verify the downloaded file
print "Verifying downloaded file...\n";
if ($frobnitz->verify_file($chomped_filename)) {
    print "File verification successful.\n";
} else {
    die "File verification failed. Aborting further processing.\n";
}

# Step 3: Add watermark to the downloaded video
my $final_file = $frobnitz->add_watermark($chomped_filename);
print "Final watermarked video is at: $final_file\n";

