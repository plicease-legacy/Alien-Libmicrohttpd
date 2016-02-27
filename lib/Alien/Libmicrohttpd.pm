package Alien::Libmicrohttpd;

use strict;
use warnings;
use File::Spec;
use File::ShareDir ();
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

  if(my $alien_builder_data = $class->_alien_builder_data)
  {
    return $alien_builder_data->{config}->{$name};
  }

  return $class->SUPER::config($name);
}

sub Alien::Base::_alien_builder_data
{
  my($self) = @_;
  
  my $class = blessed $self || $self;
  my $dist = $class;
  $dist =~ s/::/-/g;
  my $dir = eval { File::ShareDir::dist_dir($dist) };
  return unless defined $dir && -d $dir;
  my $filename = File::Spec->catfile($dir, 'alien_builder.json');
  return unless -r $filename;

  require JSON::PP;
  open my $fh, '<', $filename;    
  $config = JSON::PP->new
    ->filter_json_object(sub {
      my($object) = @_;
      my $class = delete $object->{'__CLASS__'};
      return unless $class;
      bless $object, $class;
    })->decode(do { local $/; <$fh> });
  close $fh;

  # avoid re-reading on next call
  if($class ne 'Alien::Base')
  {
    my $method = join '::', $class, '_alien_builder_data';
    no strict 'refs';
    *{$method} = sub { $config };
  }

  $config;
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
