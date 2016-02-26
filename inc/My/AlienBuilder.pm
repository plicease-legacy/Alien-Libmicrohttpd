package inc::My::AlienBuilder;

use strict;
use warnings;

use Moose;
use List::Util qw( first );
with 'Dist::Zilla::Role::InstallTool';
with 'Dist::Zilla::Role::AfterBuild';

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
  
  $content = substr($content, 0, $pos) . 
    "\n\n" .
    "# inserted by " . blessed($self) . ' ' . ($self->VERSION||'dev') . "\n" .
    join("\n", $self->_alien_builder_mm_args) . "\n" .
    substr($content, $pos) .
    "\n\n" .
    "# inserted by " . blessed($self) . ' ' . ($self->VERSION||'dev') . "\n" .
    join("\n", $self->_alien_builder_mm_postamble);
  
  $file->content($content);
}

sub builder_args
{
  my($self) = @_;
  
  return {
    dist_name => $self->zilla->name,
    retriever => [ "http://ftp.gnu.org/gnu/libmicrohttpd/" => { pattern => '^libmicrohttpd-.*\.tar\.gz$' } ],
  }
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

sub _alien_builder_mm_args
{
  my($self) = @_;
  
  (
    'use Alien::Builder::MM;',
    'my ' . $self->_dump_as($self->builder_args, '*AlienBuilderArgs'),
    'my $ab = Alien::Builder::MM->new(%AlienBuilderArgs);',
    '%WriteMakefileArgs = $ab->mm_args(%WriteMakefileArgs);',
    'my %AlienBuildRequires = %{ (do { my %h = $ab->mm_args; \%h })->{BUILD_REQUIRES} };',
    '$FallbackPrereqs{$_} = $AlienBuildRequires{$_} for keys %AlienBuildRequires;',
    '$ab->save;',
  )
}

sub _alien_builder_mm_postamble
{
  (
   'sub MY::postamble {',
   '  $ab->mm_postamble;',
   '}',
  );
}

1;
