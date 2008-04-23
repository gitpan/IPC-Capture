# Test file
# Run this like so: `perl 02-can_run-IPC-Capture.t'
#   doom@kzsu.stanford.edu     2008/04/15 01:02:48

use warnings;
use strict;
$|=1;
use Data::Dumper;
use File::Copy qw( copy );
use File::Basename qw( fileparse basename dirname );
use File::Spec;
use List::Util qw( first );
use Test::More;
use Test::Differences;

use FindBin qw( $Bin );
use lib "$Bin/../lib";
use lib "$Bin/lib";

my $DEBUG = 0;
my $CHOMPALOT = 1;

# randomly select some program in the path to search for...
# but if this fails for some reason, fall back on 'perl' (if in path).
my $target_program = find_some_program_in_path() || find_perl_in_path();

if( defined( $target_program ) ) {
  plan tests => 9;
} else {
  plan skip_all => '';
}

my %target = ( 'likely' =>
                  $target_program,
                'unlikely' =>
                  'morgenthaler_bupkes_nadzornika_nodoze_doom_cracked',
              );

if ($DEBUG) {
  print STDERR "Searching for program: $target_program\n";
  print STDERR "Also doing designed-to-fail searches on: \n $target{unlikely}\n";
}

my $CLASS = 'IPC::Capture';
use_ok( $CLASS );

{#3, #4, #5, #6
  my @methods = ('can_run_qx_which', 'can_run_qx_path_glob');
  foreach my $method (@methods) {
    my $test_name = "Testing $method directly:";
    my $ic = $CLASS->new();
    my ($target, $found);
    $target = $target{ likely };
    $found = $ic->$method( $target );
    like($found, qr{ \b $target $ }xms , "$test_name found target") ||
      print STDERR "return value: $found\n";

    $target = $target{ unlikely };
    $found = $ic->$method( $target );
    ok( not( $found ), "$test_name: no success finding a crazy target") ||
      print STDERR "return value: $found\n";
  }
}

{ #7, #8, #9, #10
  my @ways = ('qx', 'ipc_cmd');
  foreach my $way (@ways) {
    my $test_name = "Testing can_run working $way way:";
    my $ic = $CLASS->new( {way => $way} );
    my ($target, $found);
    $target = $target{ likely };
    $found = $ic->can_run( $target );
    like($found, qr{ \b $target $ }xms , "$test_name found target") ||
      print STDERR "return value: $found\n";

    $target = $target{ unlikely };
    $found = $ic->can_run( $target );
    ok( not( $found ), "$test_name: no success finding a crazy target") ||
      print STDERR "return value: $found\n";
  }
}

###
# end main, into the subs

# Picks a random location out of the path, and a random executable
# out of that location.  Uses "opendir/readir" to get a modicum
# of difference from the way the "can_run" works, using globs.
# Avoids using empty directories, and has a bailout feature to
# prevent infinite loops from hanging things.
sub find_some_program_in_path {
  my @path = grep { -d $_ } File::Spec->path();

  # preparing to bail out of infinite loops
  my $count = 0;
  my $limit = 1000;

  my @files;
  do {
    $count++;
    return if $count > $limit;
    my $pick = int( rand( scalar( @path )));
    my $loc = $path[ $pick ];
    print STDERR "Examining pick $pick loc: $loc\n" if $DEBUG;
    chdir( $loc );
    opendir(my $dirh, $loc) or die "could not opendir $loc: $!";
    @files = readdir($dirh);
    closedir $dirh;
  } until ( scalar( @files ) > 3 );  # want a dir that isn't empty

  my $file;
  $count = 0;
  do {
    $count++;
    return if $count > $limit;
    my $pick = int( rand( scalar( @files )));
    $file = $files[ $pick ];
  } until( -x $file && -f $file );
  my $program = $file;

  return $program;
}

# Looking for a 'perl' somewhere in the path
sub find_perl_in_path {
  my $running_perl = $^X;
  print STDERR "running_perl: $running_perl\n" if $DEBUG;
  my ($perlname, $path, undef) = fileparse( $running_perl );
  print STDERR "perlname: $perlname\n" if $DEBUG;

  my @targets = ('perl', $perlname);

  my @path = grep { -d $_ } File::Spec->path();

  foreach my $loc (@path) {

    opendir(my $dirh, $loc) or die "could not opendir $loc: $!";
    chdir( $loc );

    foreach my $file ( readdir($dirh) ) {
      foreach my $target (@targets) {
        if ($file eq $target) {
          return $file;
        }
      }
    }
  }
  return;
}
