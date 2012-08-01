#!/usr/bin/perl

#
# This idea is stolen from Dominic Humphries.
# http://geekblog.oneandoneis2.org/index.php/2012/07/10/another-little-convenience
#

use v5.10;
use strict;
use warnings;

use Getopt::Std;
use File::Spec;

my $EDITOR_COMMAND = 'open -a "/Applications/Sublime Text 2.app/Contents/MacOS/Sublime Text 2"';
my $OPEN_WORKDIR   = 1;
my $SHA            = '';

my $GIT_STATUS = 'git status 2> /dev/null';
my $GIT_SHOW   = 'git show --raw';

###

main();

sub main {
    parse_opts();

    unless ( qx( $GIT_STATUS ) ) {
        say( 'Not a git repository (or any of the parent directories)' );

        exit;
    }

    my $working_dir = get_working_dir();

    my $git_show = $GIT_SHOW;
    $git_show .= ' ' . $SHA if ( $SHA );

    my @gitstat = qx( $git_show );

    my @files   = ();

    foreach my $line ( @gitstat ) {
        if ( $line =~ /^:\d{6}\s\d{6}\s[a-f0-9]{7}\.\.\.\s[a-f0-9]{7}\.\.\.\s(?:[AMTUX]|(?:[CR]\d{1,3}\s\S+))\s(\S+)$/i ) {
            my $file = File::Spec->catfile( $working_dir, $1 );
            push( @files, $file );
        }
    }

    my $file_count = scalar( @files );

    confirm_large_commits( $file_count );

    my $command = $EDITOR_COMMAND;
    $command .= ' ' . $working_dir if ( $OPEN_WORKDIR );
    $command .= ' ' . join( ' ', @files );

    exec( $command );
}

sub confirm_large_commits {
    my ( $file_count ) = @_;

    if ( $file_count > 9 ) {
        say( "There are $file_count files, are you sure you want to do this? (Yes|yes|No|no) [Yes]" );

        my $input = <STDIN>;

        exit if ( $input =~ /no/i );
    }
}

sub parse_opts {
    my %opts;
    getopts( 'ne:s:', \%opts );

    $EDITOR_COMMAND = $opts{e} if ( $opts{e} );
    $SHA            = $opts{s} if ( $opts{s} );
    $OPEN_WORKDIR   = 0        if ( $opts{n} );
}

sub get_current_dir_abs {
    return File::Spec->rel2abs( File::Spec->curdir() );
}

sub get_working_dir {
    my $working_dir = get_current_dir_abs();

    while ( !-d File::Spec->catdir( $working_dir, '.git' ) ) {
        $working_dir = get_upper_dir( $working_dir );
    }

    return $working_dir;
}

sub get_upper_dir {
    my ( $dir ) = @_;

    my @dirs = File::Spec->splitdir( $dir );

    pop( @dirs );

    return File::Spec->catdir( @dirs );
}
