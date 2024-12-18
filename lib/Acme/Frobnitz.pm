package Acme::Frobnitz;

use strict;
use warnings;
use IPC::System::Simple qw(capturex);
use Cwd qw(abs_path);
use File::Spec;
use File::stat;
use File::Basename;
use FindBin;
use POSIX qw(strftime);

our $VERSION = '0.03';

sub new {
    my ($class) = @_;
    return bless {}, $class;
}

sub _get_script_path {
    my ($class, $script_name) = @_; # Resolve base directory dynamically
    my $base_dir = abs_path("$FindBin::Bin/.."); # One level up from bin
    my $script_path = File::Spec->catfile($base_dir, 'bin', $script_name);

    unless (-x $script_path) {
        die "Script $script_path does not exist or is not executable.\n";
    }

    return $script_path;
}

sub download {
    my ($class, $hyperlink) = @_;
    die "No hyperlink provided.\n" unless $hyperlink;

    my $script_path = $class->_get_script_path("call_download.sh");
    my $output;
    eval {
        $output = capturex("bash", $script_path, $hyperlink);
    };
    if ($@) {
        die "Error executing $script_path with hyperlink $hyperlink: $@\n";
    }

    return $output;
}

sub add_watermark {
    my ($class, $input_video) = @_;
    die "Input video file not provided.\n" unless $input_video;

    my $script_path = $class->_get_script_path("call_watermark.py");
    my $output;
    eval {
        $output = capturex("bash", $script_path, $input_video);
    };
    if ($@) {
        die "Error adding watermark with $script_path: $@\n";
    }

    return $output;
}

sub verify_file {
    my ($class, $file_path) = @_;
    die "File path not provided.\n" unless $file_path;

    my $abs_path = abs_path($file_path) // $file_path;

    if (-e $abs_path) {
        print "File exists: $abs_path\n";

        # File size
        my $size = -s $abs_path;
        print "File size: $size bytes\n";

        # File permissions
        my $permissions = sprintf "%04o", (stat($abs_path)->mode & 07777);
        print "File permissions: $permissions\n";

        # Last modified time
        my $mtime = stat($abs_path)->mtime;
        print "Last modified: ", strftime("%Y-%m-%d %H:%M:%S", localtime($mtime)), "\n";

        # Owner and group
        my $uid = stat($abs_path)->uid;
        my $gid = stat($abs_path)->gid;
        print "Owner UID: $uid, Group GID: $gid\n";

        return 1; # Verification success
    } else {
        print "File does not exist: $abs_path\n";
        my $dir = dirname($abs_path);

        # Report directory details
        print "Inspecting directory: $dir\n";
        opendir my $dh, $dir or die "Cannot open directory $dir: $!\n";
        my @files = readdir $dh;
        closedir $dh;

        print "Directory contents:\n";
        foreach my $file (@files) {
            next if $file =~ /^\.\.?\$/; # Skip . and ..
            my $file_abs = File::Spec->catfile($dir, $file);
            my $type = -d $file_abs ? 'DIR ' : 'FILE';
            my $size = -s $file_abs // 'N/A';
            print "$type - $file (Size: $size bytes)\n";
        }

        return 0; # Verification failed
    }
}

1; # End of Acme::Frobnitz

