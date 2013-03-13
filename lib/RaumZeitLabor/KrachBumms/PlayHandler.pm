package RaumZeitLabor::KrachBumms::PlayHandler;

use 5.12.0;
use strict;
use warnings;

use JSON::XS;
use RaumZeitLabor::KrachBumms;

use parent qw(Tatsumaki::Handler);
__PACKAGE__->asynchronous(1);

use Audio::Play::MPG123;
my $player = new Audio::Play::MPG123;
my $idle_w;

sub get {
    my($self, $query) = @_;
    $self->response->content_type('application/json');
    my ($f, $l) = RaumZeitLabor::KrachBumms::get_file($query);

    # "This function should be called regularly, since mpg123 will stop playing
    # when it can't write out events because the perl program is no longer
    # listening..."
    $idle_w ||= AnyEvent->idle(cb => sub { $player->poll; undef $idle_w });

    if ($f) {
        say "playing $f";
        $player->load($f);
    }
    $self->write(encode_json {
        status => $f ? "success" : "notfound",
        file   => $l
    });
    $self->finish;
}

42;
# vim: set ts=4 sw=4 sts=4 expandtab: 
