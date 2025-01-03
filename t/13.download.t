#!/usr/bin/perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;
use Cwd 'abs_path';
use Log::Log4perl;

# Initialize Log4perl
Log::Log4perl->init(\<<'END');
log4perl.logger                    = INFO, FileAppender

log4perl.appender.FileAppender     = Log::Log4perl::Appender::File
log4perl.appender.FileAppender.filename = logs/acme-frobnitz.log
log4perl.appender.FileAppender.layout   = Log::Log4perl::Layout::PatternLayout
log4perl.appender.FileAppender.layout.ConversionPattern = %d [%p] %m%n
END

# Create logger
my $logger = Log::Log4perl->get_logger();

# Adding the library path relative to this test script
use lib "$FindBin::Bin/../lib";
use Acme::Frobnitz;

# URL to test the download functionality
my $test_url = 'https://www.youtube.com/watch?v=dQw4w9WgXcQ';

# Set the name of the script to be tested
my $executable_name = 'call_download.sh';

# Dynamically resolve the path to the script being tested
my $script_path;
my $base_dir = abs_path("$FindBin::Bin/..");
my $bin_dir = File::Spec->catfile($base_dir, 'bin');

$logger->info("Resolved base directory: $base_dir");
$logger->info("Resolved bin directory: $bin_dir");

# Check if the script exists in the bin directory
if (-e File::Spec->catfile($bin_dir, $executable_name)) {
    $script_path = File::Spec->catfile($bin_dir, $executable_name);
    $logger->info("Resolved script path: $script_path");
} else {
    $logger->error("$executable_name not found in bin directory: $bin_dir");
    BAIL_OUT("Cannot proceed without $executable_name");
}

# BEGIN TESTS

$logger->info("Starting test suite for Acme::Frobnitz");

# Ensure the script exists and is executable
ok(-e $script_path, "Script exists at $script_path");
$logger->info("Script exists: $script_path");
ok(-x $script_path, "Script is executable");
$logger->info("Script is executable: $script_path");

# Ensure the module has the download method
can_ok('Acme::Frobnitz', 'download') or do {
    $logger->error("download method not found in Acme::Frobnitz");
    BAIL_OUT("download method not found in Acme::Frobnitz");
};

$logger->info("Test URL for download: $test_url");

# Attempt to download a YouTube video
my $output_file;

# Diagnostic block for ensuring the environment is correctly set up
sub run_diagnostics {
    $logger->info("Bash version: " . `bash --version`);
    $logger->info("Current working directory: " . `pwd`);
    $logger->info("Listing of bin directory: " . `ls -l $bin_dir`);
}

run_diagnostics();

# Try to perform the download and capture potential errors
eval {
    $output_file = Acme::Frobnitz->download($test_url);
};

if ($@) {
    $logger->error("Error during download: $@");
    fail("Download method threw an exception");
} else {
    ok($output_file, "Download method completed without errors");
    $logger->info("Download method completed successfully");

    # Verify the output file has the expected `.webm` extension
    if ($output_file =~ /\.webm$/) {
        pass("Output file has the expected .webm extension");
        $logger->info("Output file has the expected .webm extension: $output_file");
    } else {
        fail("Output file does not have the expected .webm extension");
        $logger->error("Output file does not have the expected .webm extension: $output_file");
    }
}

# Cleanup: remove the output file
#unlink $output_file or $logger->error("Could not remove output file: $output_file");

done_testing();

