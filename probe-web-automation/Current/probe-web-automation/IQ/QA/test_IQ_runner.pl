#!/usr/bin/perl

use strict;
use lib '/opt/probe-web-automation';
use IQ;

if(@ARGV == 3){

    my $test_to_run = @ARGV[0];
    my $probe_type = @ARGV[1];
    my $args = @ARGV[2]; # In a | delimited format
        # 'ip|Admin User|Admin password|etc if needed'

    my @vars = split( /\|/, $args );

    #setup object
    my $iq = IQ->new();

    my $test_output = $iq->test_runner( $test_to_run, $probe_type, $args );

    print $test_output;
}
else {
    print "Usage: script.pl <probe's IP> <login user> <login password> <add user's name> <add user's password> <add user's group [public|private|admin]>\n\n";
}
