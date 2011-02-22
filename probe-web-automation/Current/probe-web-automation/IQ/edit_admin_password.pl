#!/usr/bin/perl

use strict;
use lib '/opt/probe-web-automation';
use IQ;

if(@ARGV == 6){

        my $ip = @ARGV[0];
	my $admin_login = @ARGV[1];
        my $admin_password = @ARGV[2];
	my $new_admin_password = @ARGV[3];

	#setup NSP_Test object
        my $test = IQ->new();

        $test->set_page_ip($ip);

	$test->start_mech();

	#login
	print "Loggin in...\r\n";

	$test->login("$admin_login","$admin_password");

	print "Logged in\r\n";

	$test->change_admins_password( $new_admin_password );

	print "Done\r\n";
}
else {
	print "Usage: script.pl <probe's IP> <login user> <login password> <add user's name> <add user's password> <add user's group [public|private|admin]>\n\n";
}
