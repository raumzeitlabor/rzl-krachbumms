#!perl

use Test::More tests => 1;

BEGIN {
    use_ok( 'RaumZeitLabor::KrachBumms' ) || print "Bail out!\n";
}

diag( "Testing RaumZeitLabor::KrachBumms $RaumZeitLabor::KrachBumms::VERSION, Perl $], $^X" );
