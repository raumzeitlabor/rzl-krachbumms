#!perl

use strict;

use Test::More;
use Data::Dumper;
use RaumZeitLabor::KrachBumms;

use File::Basename;
use File::Spec::Functions;
use File::Path qw/remove_tree/;
use File::Copy::Recursive qw/rcopy/;
use File::Temp qw/tempfile tempdir/;

my $root = tempdir(CLEANUP => 1);

my $kb = RaumZeitLabor::KrachBumms::init($root);
$RaumZeitLabor::KrachBumms::inotify->blocking(0);

ok($kb, "could init krachbumms");
is(keys %RaumZeitLabor::KrachBumms::all, 1, "indexed root dir");
is(@{$RaumZeitLabor::KrachBumms::all{'/'}}, 0, "no files in root dir");

# put some files in there
my (undef, $f1) = tempfile(DIR => $root, SUFFIX => '.ogg');
my (undef, $f2) = tempfile(DIR => $root, SUFFIX => '.mp3');
my (undef, $f3) = tempfile(DIR => $root, SUFFIX => '.filtered');

$RaumZeitLabor::KrachBumms::inotify->read;
is(@{$RaumZeitLabor::KrachBumms::all{'/'}}, 2, "two files in root dir");

unlink $f2;
$RaumZeitLabor::KrachBumms::inotify->read;
is(@{$RaumZeitLabor::KrachBumms::all{'/'}}, 1, "one file removed");

my $dir = tempdir(DIR => $root);
$RaumZeitLabor::KrachBumms::inotify->read;
is(keys %RaumZeitLabor::KrachBumms::all, 2, "indexed new dir");
is(@{$RaumZeitLabor::KrachBumms::all{'/'.basename($dir)}}, 0, "no files in new dir");

(undef, $f2) = tempfile(DIR => $dir, SUFFIX => '.ogg');
$RaumZeitLabor::KrachBumms::inotify->read;
is(@{$RaumZeitLabor::KrachBumms::all{'/'.basename($dir)}}, 1, "one file in new dir");

remove_tree($dir);
$RaumZeitLabor::KrachBumms::inotify->read;
is(keys %RaumZeitLabor::KrachBumms::all, 1, "removed dir");

$dir = tempdir(DIR => $root);
my $dir2 = tempdir(DIR => $dir);
$RaumZeitLabor::KrachBumms::inotify->read;
is(keys %RaumZeitLabor::KrachBumms::all, 3, "two new dir paths");

# put some files in there
my (undef, $f3) = tempfile(DIR => $dir, SUFFIX => '.ogg');
my (undef, $f3) = tempfile(DIR => $dir, SUFFIX => '.ogg');
my (undef, $f3) = tempfile(DIR => $dir2, SUFFIX => '.mp3');
my (undef, $f3) = tempfile(DIR => $dir2, SUFFIX => '.ogg');
my (undef, $f3) = tempfile(DIR => $dir2, SUFFIX => '.ogg');

$RaumZeitLabor::KrachBumms::inotify->read;
is(@{$RaumZeitLabor::KrachBumms::all{'/'.basename($dir)}}, 2, "two files in first hierarchy");
is(@{$RaumZeitLabor::KrachBumms::all{'/'.catfile(basename($dir), basename($dir2))}}, 3, "three files in second hierarchy");

rename $dir2, catfile($dir, basename($dir));
$RaumZeitLabor::KrachBumms::inotify->read;
ok($RaumZeitLabor::KrachBumms::all{'/'.catfile(basename($dir), basename($dir))}, "renamed folder");
is(@{$RaumZeitLabor::KrachBumms::all{'/'.catfile(basename($dir), basename($dir))}}, 3, "files still exist");

done_testing;
