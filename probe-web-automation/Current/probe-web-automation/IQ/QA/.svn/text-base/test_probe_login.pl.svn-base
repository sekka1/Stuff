#!/usr/bin/perl

use strict;
use lib '/opt/probe-web-automation';
use IQ;

if(@ARGV == 4){

    my $probe_type = @ARGV[0];
    my $ip = @ARGV[1];
    my $admin_login = @ARGV[2];
    my $admin_password = @ARGV[3];

    #setup object
    my $iq = IQ->new();

    $iq->set_probe_type($probe_type);
    $iq->set_page_ip($ip);

    $iq->start_mech();

    my $outcome = $iq->login("$admin_login","$admin_password");

    if( $outcome eq '1' ){
        print "OK";
    } else {
        print "Not OK";
    }
}
else {
    print "Usage: script.pl <probe's IP> <login user> <login password> <add user's name> <add user's password> <add user's group [public|private|admin]>\n\n";
}
