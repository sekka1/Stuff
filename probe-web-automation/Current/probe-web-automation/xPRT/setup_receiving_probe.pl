#!/usr/bin/perl

use strict;
use lib '/opt/probe-web-automation';
use IQ;

if(@ARGV == 4){

        my $ip = @ARGV[0];
	my $admin_login = @ARGV[1];
        my $admin_password = @ARGV[2];
	my $primary_trap_destination = @ARGV[3];

	#setup NSP_Test object
        my $test = IQ->new();

        $test->set_page_ip($ip);

	$test->start_mech();

	#login to NSP
	print "Loggin in...\r\n";

	$test->login("$admin_login","$admin_password");

	print "Logged in\r\n";

	# Set primary trap address
	print "Setting primary trap address\r\n";
	$test->systemconfiguration_edit_set_primary_trap_destination( $primary_trap_destination );

	# Save and reset
	print "Save and resetting\r\n";
	$test->configurationmanagement_saveconfiguration_saveandreset();

	print "Waiting for reset\r\n";
	sleep(60);

	#login to NSP
	print "Loggin in...\r\n";

	$test->login("$admin_login","$admin_password");

	print "Logged in\r\n";

	print "Setting xPRT IP and starting perf test\r\n";
	$test->systemconfiguration_set_xPRT_and_start_performance_test( $primary_trap_destination );

	print "Done\r\n";
}
else {
	print "Usage: script.pl <probe's IP> <login user> <login password> <add user's name> <add user's password> <add user's group [public|private|admin]>\n\n";
}
