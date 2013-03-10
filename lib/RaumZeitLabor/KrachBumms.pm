package RaumZeitLabor::KrachBumms;

use 5.12.0;
use strict;
use warnings;

use AnyEvent;
use File::Find;
use File::Spec::Functions;
use File::Basename;
use Linux::Inotify2;

use Exporter qw/import/;
our @EXPORT = qw(get_file);

use Data::Dumper;
use Tatsumaki::Handler;
use Tatsumaki::Application;

use RaumZeitLabor::KrachBumms::IndexHandler;
use RaumZeitLabor::KrachBumms::PlayHandler;

=head1 NAME

RaumZeitLabor::KrachBumms - Ein kleiner Soundserver.

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';
$|++;

my ($inotify, $poller);
my $file_regex = qr/\.(?:mp3|ogg)$/;
our (%all, $rootdir);

=head1 SYNOPSIS

Quick summary of what the module does.

Perhaps a little code snippet.

    use RaumZeitLabor::KrachBumms;

    my $foo = RaumZeitLabor::KrachBumms->new();
    ...

=head1 EXPORT

A list of functions that can be exported.  You can delete this section
if you don't export anything, such as for a purely object-oriented module.

=head1 SUBROUTINES/METHODS

=cut

sub add_file {
    my $f = canonpath shift;

    # $_ will be basename of file within find { }
    # we need the full path
    if (defined $File::Find::name) {
        $f = $File::Find::name;
    }

    # skip all files that do not match
    -f $f && $f !~ $file_regex && return;

    # strip rootdir from path
    (my $basename = $f) =~ s/$rootdir//;
    $basename = '/' unless $basename;

    if (-f $f) {
        my ($filename) = fileparse($basename);
        my $dir_path   = dirname($basename); # we want no trailing slash
        push @{$all{$dir_path}}, $filename;

        say "added file $f";
    }

    if (-d $f && !defined $all{$basename}) {
        $all{$basename} = [];

        # add watcher
        $inotify->watch($f,
            IN_CREATE | IN_DELETE | IN_DELETE_SELF | IN_MOVE_SELF |
            IN_MOVED_FROM | IN_MOVED_TO, \&inotify_cb);

        say "added folder $f";
        # scan again (in case folder was moved)
        find { wanted => \&add_file }, $f unless $File::Find::name;
    }
}

sub inotify_cb {
    my $e = shift;
    my $filename  = $e->fullname;
    if ($e->IN_CREATE | $e->IN_MOVED_TO | $e->IN_MOVE_SELF) {
        add_file ($filename);
    } elsif ($e->IN_DELETE | $e->IN_DELETE_SELF | $e->IN_MOVED_FROM) {
        $e->w->cancel if (-d $filename);
        remove_file ($filename);
    }
}

# returns path to a random file, if directory given
# returns path to file, if file given.
# or undef.
sub get_file {
    my $basename = shift;
    $basename = '/'.$basename unless ($basename =~ /^\//);

    # check if it is a folder
    if (defined $all{$basename}) {
        # check if there are files at all
        return undef unless scalar @{$all{$basename}};

        # return a random file path
        my $rand = rand(scalar @{$all{$basename}});
        my $file = @{$all{$basename}}[$rand];
        return catfile($rootdir, $basename, $file), fileparse($file);

    # seems to be a file
    } else {
        my ($filename) = fileparse($basename);
        my $dir_path   = dirname($basename); # we dont want no trailing slash

        # check if the path exists
        return undef unless defined $all{$dir_path};

        # return the full path
        my @f = grep {$_ eq $filename} @{$all{$dir_path}};
        if (scalar @f == 1) {
            return catfile($rootdir, $dir_path, $f[0]), $filename;
        }
        return undef;
    }
}

sub remove_file {
    my $f = shift;

    # strip rootdir from path
    (my $basename = $f) =~ s/$rootdir//;
    return unless $basename;

    my ($filename) = fileparse($basename);

    if (defined $all{$basename}) {
        delete $all{$basename};
        say "removed folder $f";
    } else {
        # it's a file!
        my ($filename) = fileparse($basename);
        my $dir_path   = dirname($basename); # we dont want no trailing slash
        my @dirs = grep {$_ ne $filename} @{$all{$dir_path}};

        if (@dirs < @{$all{$dir_path}}) {
            $all{$dir_path} = \@dirs;
            say "removed file $f";
        }
    }
}

sub webapp {
    $rootdir = shift;
    $inotify = Linux::Inotify2->new() or die "could not create inotify: $!\n";

    # find all directories and add inotify watchers
    # find all files (d and f) and collect them
    find { wanted => \&add_file }, $rootdir;

    $poller = AnyEvent->io(
        fh   => $inotify->fileno,
        poll => 'r',
        cb   => sub { $inotify->poll }
    ); 

    my $app = Tatsumaki::Application->new([
        '/'          => 'RaumZeitLabor::KrachBumms::IndexHandler',
        '/play/(.*)' => 'RaumZeitLabor::KrachBumms::PlayHandler',
    ]);
    
    $app->psgi_app;
}

=head1 AUTHOR

Simon Elsbrock, C<< <simon at iodev.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-raumzeitlabor-krachbumms at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=RaumZeitLabor-KrachBumms>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc RaumZeitLabor::KrachBumms


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=RaumZeitLabor-KrachBumms>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/RaumZeitLabor-KrachBumms>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/RaumZeitLabor-KrachBumms>

=item * Search CPAN

L<http://search.cpan.org/dist/RaumZeitLabor-KrachBumms/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2013 Simon Elsbrock.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; version 2 dated June, 1991 or at your option
any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

A copy of the GNU General Public License is available in the source tree;
if not, write to the Free Software Foundation, Inc.,
59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.


=cut

1; # End of RaumZeitLabor::KrachBumms
# vim: set ts=4 sw=4 sts=4 expandtab: 
