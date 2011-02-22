#!/usr/bin/perl

use strict;
use lib '/opt/probe-web-automation';
use IQ;

if(@ARGV == 5){

	my $list_of_probes = 'gkan.webhop.net,1.1.1.1';

	my $admin_login = @ARGV[0];
        my $admin_password = @ARGV[1];
	my $add_users_name = @ARGV[2];
	my $add_users_password = @ARGV[3];
	my $add_users_access_level = @ARGV[4];

	# Separate the probe's ip list
    	my @probe_list = split( /,/, $list_of_probes );

	foreach my $aProbe ( @probe_list ){

		#setup object
		my $test = IQ->new();

		$test->set_page_ip( $aProbe );

		$test->start_mech();

		#login to NSP
		print "Loggin in: $aProbe...\r\n";

		$test->login("$admin_login","$admin_password");

		print "Logged in\r\n";

		$test->add_user( $add_users_name, $add_users_password, $add_users_access_level );

		print "Done\r\n";

	}
}
else {
	print "Usage: script.pl <probe's IP> <login user> <login password> <add user's name> <add user's password> <add user's group [public|private|admin]>\n\n";
}
