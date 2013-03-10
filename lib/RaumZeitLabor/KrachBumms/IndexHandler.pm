package RaumZeitLabor::KrachBumms::IndexHandler;

use 5.12.0;
use strict;
use warnings;

use JSON::XS;
use RaumZeitLabor::KrachBumms;

use parent qw(Tatsumaki::Handler);
__PACKAGE__->asynchronous(1);

my $json = JSON->new->allow_nonref;

sub get {
    my($self, $query) = @_;
    $self->response->content_type('application/json');
    $self->write($json->pretty->encode(\%RaumZeitLabor::KrachBumms::all));
    $self->finish;
}
# vim: set ts=4 sw=4 sts=4 expandtab: 
