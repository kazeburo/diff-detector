#!/usr/bin/perl

use strict;
use warnings;
use Digest::MD5 qw/md5_hex/;
use File::Spec;
use File::Temp qw(tempfile);
use Getopt::Long;
use File::Copy;

sub find_path {
    my $pg = shift;
    my $path;
    for ( split /:/, $ENV{PATH} ) {
        if ( -x "$_/$pg" ) {
            $path = "$_/$pg";
            last;
        }
    }
    $path = "/usr/local/bin/$pg" if !$path && -x "/usr/local/bin/$pg";
    $path;
}

sub cap_cmd {
    my ($cmdref) = @_;
    pipe my $logrh, my $logwh
        or die "Died: failed to create pipe:$!\n";
    my $pid = fork;
    if ( ! defined $pid ) {
        die "Died: fork failed: $!\n";
    } 

    elsif ( $pid == 0 ) {
        #child
        close $logrh;
        open STDOUT, '>&', $logwh
            or die "Died: failed to redirect STDOUT\n";
        close $logwh;
        exec @$cmdref;
        die "Died: exec failed: $!\n";
    }
    close $logwh;
    my $result;
    while(<$logrh>){
        $result .= $_;
    }
    close $logrh;
    while (wait == -1) {}
    my $exit_code = $?;
    $exit_code = $exit_code >> 8;
    return ($result, $exit_code);
}

my $identifier = "";

Getopt::Long::Configure ("no_ignore_case");
GetOptions(
    'identifier' => \$identifier,
    "h|help"     => \my $help,
);

my @command = @ARGV;
$|=1;

if ( $help || !@command ) {
    print qq!usage: $0 [--identifier=..] -- command args1 args2 args3\n!;
    exit($help ? 0 : 1);
}

my $diff_cmd = find_path("diff")
    or die "failed to searchdiff command";

my $comamnd_key = md5_hex($identifier,@command);
my $tmpdir = File::Spec->tmpdir();

my $prev_file = File::Spec->catfile($tmpdir, "diff-detector-".$comamnd_key);

my $cur_file;
my $cur_fh;
($cur_fh, $cur_file) = tempfile(UNLINK => 1);
binmode $cur_fh, ':unix';

pipe my $logrh, my $logwh
    or die "Died: failed to create pipe:$!";

my $pid = fork;
if ( ! defined $pid ) {
    die "Died: fork failed: $!";
}
elsif ( $pid == 0 ) {
    #child
    close $logrh;
    open STDOUT, '>&', $cur_fh or die "failed to redirect STDOUT to logfile";
    open STDERR, '>&', $logwh or die "failed to redirect STDERR to logfile";
    close $logwh;
    close $cur_fh;
    exec @ARGV;
    die "Died: exec failed: $!";
}

#parent
my $stderr = '';
close $logwh;
while(<$logrh>){
    s/(\r|\n|\r\n)/\\/g;
    $stderr .= $_ if length $stderr < 512;
}
close $logrh;

while (wait == -1) {}
my $exit_code = $?;

if ( $exit_code != 0 ) {
    print "Error: $stderr\n";
    exit $exit_code >> 8;
}

if ( ! -f $prev_file ) {
    printf 'Notice: first time execution command:"%s"'."\n", join(" ", @command);
    copy($cur_file, $prev_file) or die "Copy failed: $!";
    exit 0;
}

(my $diff_result, $exit_code) = cap_cmd([$diff_cmd, "-U","1", $prev_file, $cur_file]);
copy($cur_file, $prev_file) or die "Copy failed: $!";

if ( $exit_code == 0 ) {
    open(my $fh, $cur_file) or die $!;
    sysread($fh, my $cur, 128);
    chomp($cur);chomp($cur);
    $cur =~ s/(\n|\r|\r\n)/\\n/g;
    print "OK: no difference: ".$cur."\n";
    exit $exit_code;
}
elsif ( $exit_code == 1 ) {
    my @diff_result = split /\n/, $diff_result;
    shift @diff_result;
    shift @diff_result;
    $diff_result = join "\n", @diff_result;
    $diff_result =~ s/(\n|\r|\r\n)/\\n/g;
    print "NG: detect difference: " . substr($diff_result, 0, 512) . "\n";
    exit 2;
}

print "Error: failed execute diff\n";
exit 3;

