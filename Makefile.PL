use inc::Module::Install;

name     'RaumZeitLabor-KrachBumms';
all_from 'lib/RaumZeitLabor/KrachBumms.pm';
author   q{Simon Elsbrock <simon@iodev.org>};
license  'gpl';

build_requires 'Test::More';

requires 'EV';
requires 'AnyEvent';
requires 'JSON::XS';
requires 'Tatsumaki';
requires 'Linux::Inotify2';
requires 'Audio::Play::MPG123';

auto_install;

WriteAll;

# vim: set ts=4 sw=4 sts=4 expandtab: 
