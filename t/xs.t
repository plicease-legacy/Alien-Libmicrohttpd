use strict;
use warnings;
use Test::Stream -V1;
use Test::Alien;
use Alien::Libmicrohttpd;

plan 3;

alien_ok 'Alien::Libmicrohttpd';

xs_ok do { local $/; <DATA> }, with_subtest {
  my $version = Mhttpd::MHD_get_version();
  ok $version, "version = $version";
};

__DATA__

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include <microhttpd.h>

MODULE = Mhttpd PACKAGE = Mhttpd

const char *MHD_get_version();
