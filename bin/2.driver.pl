use strict;
use warnings;
use Acme::Frobnitz;

my $frobnitz = Acme::Frobnitz->new();

# URL of the video to download
#my $video_url = "https://www.youtube.com/shorts/CFqehDVY_zQ";
my $video_url = "https://www.instagram.com/p/DDa_FxsNtTe/";



# Download the video
my $downloaded_file = $frobnitz->download($video_url);
print "Downloaded video to: $downloaded_file\n";

# Add watermark to the downloaded video
my $final_file = $frobnitz->add_watermark($downloaded_file);
print "Final watermarked video is at: $final_file\n";

