use strict;
use warnings;
use Test::Stream -V1;
use Test::Alien;
use Alien::Libmicrohttpd;

plan 3;

alien_ok 'Alien::Libmicrohttpd';
ffi_ok { symbols => ['MHD_get_version'] }, with_subtest {
  my($ffi) = @_;
  my $version = $ffi->function(MHD_get_version => [] => 'string')->call;
  ok $version, "version = $version";
};

