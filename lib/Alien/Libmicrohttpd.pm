package Alien::Libmicrohttpd;

use strict;
use warnings;
use base qw( Alien::Base );

# ABSTRACT: Alien package for libmicrohttpd
# VERSION

my $config;
sub config
{
  # TODO: intention is to add this capability into Alien::Base
  # (while keeping back compatability for older modules using
  # the ::ConfigData interface)

  my($class, $name) = @_;

  unless($config)
  {
    require JSON::PP;
    require File::Spec;
    my $filename = File::Spec->catfile($class->dist_dir, 'alien_builder.json');
    open my $fh, '<', $filename;
    
    $config = JSON::PP->new
      ->filter_json_object(sub {
        my($object) = @_;
        my $class = delete $object->{'__CLASS__'};
        return unless $class;
        bless $object, $class;
      })->decode(do { local $/; <$fh> });

    close $fh;
  }
  
  $config->{config}->{$name};
}

sub dist_dir
{
  my($class) = @_;
  require File::ShareDir;
  my $dist = blessed $class || $class;
  $dist =~ s/::/-/g;
  File::ShareDir::dist_dir($dist);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Alien::Libmicrohttpd - Alien package for libmicrohttpd

=head1 VERSION

version 0.01

=head1 AUTHOR

Graham Ollis <plicease@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
