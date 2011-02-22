#!/usr/bin/perl

use strict;
use lib '/opt/probe-web-automation';
use IQ;

if(@ARGV == 6){

        my $ip = @ARGV[0];
	my $admin_login = @ARGV[1];
        my $admin_password = @ARGV[2];
	my $add_users_name = @ARGV[3];
	my $add_users_password = @ARGV[4];
	my $add_users_access_level = @ARGV[5];

	#setup NSP_Test object
        my $test = IQ->new();

        $test->set_page_ip($ip);

	$test->start_mech();

	#login to NSP
	print "Loggin in...\r\n";

	$test->login("$admin_login","$admin_password");

	print "Logged in\r\n";

	$test->add_user( $add_users_name, $add_users_password, $add_users_access_level );

	print "Done\r\n";
}
else {
	print "Usage: script.pl <probe's IP> <login user> <login password> <add user's name> <add user's password> <add user's group [public|private|admin]>\n\n";
}
