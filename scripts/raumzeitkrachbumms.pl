package main;

BEGIN {
    use FindBin;
    if ($FindBin::Bin =~ m,/script/?$,) {
        use lib "$FindBin::Bin/../lib";
    }
}

use 5.12.0;
use strict;
use warnings;

use EV;
use Twiggy::Server;
use Plack::Builder;
use RaumZeitLabor::KrachBumms;

my $krachbummsapp = RaumZeitLabor::KrachBumms::webapp("$FindBin::Bin/../sounds");

my $app = builder {
    $krachbummsapp;
};

my $server = Twiggy::Server->new(
    host => '127.0.0.1',
    port => 5000,
);

$server->register_service($app);

EV::loop;
# vim: set ts=4 sw=4 sts=4 expandtab: 
