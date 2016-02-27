package inc::My::AlienBuilder;

# The intent is for this module to turn into a generic interface
# that can be submitted to CPAN as Dist::Zilla::Plugin::AlienBuilder

use strict;
use warnings;

use Moose;
use List::Util qw( first );
with 'Dist::Zilla::Role::InstallTool';
with 'Dist::Zilla::Role::AfterBuild';
with 'Dist::Zilla::Role::MetaProvider';
with 'Dist::Zilla::Role::TextTemplate';

has ab_class => ( is => 'ro', isa => 'Str', default => 'Alien::Builder::MM' );

has $_ => ( is => 'ro', isa => 'Bool' )
  for qw( arch autoconf_with_pic dest_dir isolate_dynamic msys );

has $_ => ( is => 'ro', isa => 'Str' )
  for qw( name build_dir extractor ffi_name interpolator provides_cflags provides_libs retriever_class version_check );

has $_ => ( is => 'ro', isa => 'ArrayRef[Str]' )
  for qw( build_commands install_commands test_commands );

# TODO: bin_requires
# TODO: env
# TODO: helper
# TODO: inline_auto_include
# TODO: retriever

around mvp_multivalue_args => sub {
  my($orig, $self) = @_;
  return ($self->$orig, qw( build_commands install_commands test_commands ));
};

sub after_build
{
  my($self) = @_;
  $self->log_fatal('Build.PL detected, this plugin only works with MakeMaker')
    if first { $_->name eq 'Build.PL' } @{ $self->zilla->files };
}

sub setup_installer
{
  my($self) = @_;
  
  my $file = first { $_->name eq 'Makefile.PL' } @{ $self->zilla->files };
  $self->log_fatal('No Makefile.PL') unless $file;
  
  my $content = $file->content;
  
  $self->log_fatal('failed to find position in Makefile.PL...')
    unless $content =~ /my %FallbackPrereqs = \((?:\n[^;]+^)?\);$/mg;
    
  my $pos = pos($content);

  $content = $self->fill_in_string($self->template, {
    before => substr($content, 0, $pos),
    after  => substr($content, $pos),
    self   => \$self,
  }, {});
  
  $file->content($content);
}

sub builder_args
{
  my($self) = @_;

  my %args = (
    dist_name => $self->zilla->name,
    retriever => [ "http://ftp.gnu.org/gnu/libmicrohttpd/" => { pattern => '^libmicrohttpd-.*\.tar\.gz$' } ],
  );
  
  foreach my $accessor (map { $_->name } __PACKAGE__->meta->get_all_attributes)
  {
    # TODO: can we get more meta on this?  What happens
    # if generic plugin attributes get added?
    next if $accessor =~ /^(logger|zilla|plugin_name|ab_class|delim)$/;
    my $value = $self->$accessor;
    next unless defined $value;
    $args{$accessor} = $value;
  }
  
  \%args;
}

sub metadata
{
  my($self) = @_;
  { dynamic_config => 1 };
}

sub _dump_as
{
  my($self, $ref, $name) = @_;
  require Data::Dumper;
  my $dumper = Data::Dumper->new([$ref], [$name]);
  $dumper->Sortkeys(1);
  $dumper->Indent(1);
  $dumper->Useqq(1);
  return $dumper->Dump;
}

my $template;
sub template
{
  $template = do { local $/; <DATA> } unless $template;
  $template;
}

1;

__DATA__
{{ $before }}

# begin inserted by {{ blessed $self }} {{ $self->VERSION || 'dev' }}
{{ $self->ab_class ne 'Alien::Builder::MM' ? 'use lib "inc"' : '' }}
my {{ $self->_dump_as($self->builder_args, '*AlienBuilderArgs') }}
my $ab = {{ $self->ab_class }}->new(%AlienBuilderArgs);
%WriteMakefileArgs = $ab->mm_args(%WriteMakefileArgs);
my %AlienBuildRequires = %{ (do { my %h = $ab->mm_args; \%h })->{BUILD_REQUIRES} };
$FallbackPrereqs{$_} = $AlienBuildRequires{$_} for keys %AlienBuildRequires;
$ab->save;
# end   inserted by {{ blessed $self }} {{ $self->VERSION || 'dev' }}

{{ $after }}

# begin inserted by {{ blessed $self }} {{ $self->VERSION || 'dev' }}
sub MY::postamble {
  $ab->mm_postamble;
}
# end   inserted by {{ blessed $self }} {{ $self->VERSION || 'dev' }}
