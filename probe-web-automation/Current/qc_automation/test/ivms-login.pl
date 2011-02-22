#!/usr/bin/perl

use strict;
use lib '/opt/probe-web-automation';
use IVMS;

if(@ARGV == 4){

        my $ip = @ARGV[0];
	my $server_port = @ARGV[1];
	my $username = @ARGV[2];
        my $password = @ARGV[3];

	#setup NSP_Test object
        my $iVMS = IVMS->new();

        $iVMS->set_page_ip($ip, $server_port );

	$iVMS->start_mech();

	#login to NSP
	print "Loggin in...\r\n";

	$iVMS->login("$username","$password");

	print "Logged in\r\n";

        my $content = $iVMS->get_configuration_clusterManagement();

        print $content;

	print "Done\r\n";
}
else {
	print "Usage: script.pl <probe's IP> <login user> <login password> <add user's name> <add user's password> <add user's group [public|private|admin]>\n\n";
}
