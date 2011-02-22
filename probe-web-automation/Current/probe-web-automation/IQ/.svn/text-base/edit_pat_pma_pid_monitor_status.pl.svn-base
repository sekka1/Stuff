#!/usr/bin/perl

use strict;
use lib '/opt/probe-web-automation';
use IQ;

if(@ARGV == 5){

        my $ip = @ARGV[0];
	my $admin_login = @ARGV[1];
        my $admin_password = @ARGV[2];
	my $template = @ARGV[3];
	my $new_value = @ARGV[4];

	#setup NSP_Test object
        my $probe = IQ->new();

        $probe->set_page_ip($ip);

	$probe->start_mech();

	#login to NSP
	print "Loggin in...\r\n";

	$probe->login("$admin_login","$admin_password");

	print "Logged in\r\n";

	$probe->edit_pat_pma_pid_monitor_status( $template, $new_value );

	print "Done\r\n";
}
else {
	print "Usage: script.pl <probe's IP> <login user> <login password> <add user's name> <add user's password> <add user's group [public|private|admin]>\n\n";
}
