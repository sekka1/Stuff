#!/usr/bin/perl

use strict;
use lib '/opt/probe-web-automation';
use IQ;

if(@ARGV == 6){

        my $ip = @ARGV[0];
	my $admin_login = @ARGV[1];
        my $admin_password = @ARGV[2];
	my $template = @ARGV[3];
	my $enable_disable = @ARGV[4];
	my $new_value = @ARGV[5];

	#setup NSP_Test object
        my $probe = IQ->new();

        $probe->set_page_ip($ip);

	$probe->start_mech();

	#login to NSP
	print "Loggin in...\r\n";

	$probe->login("$admin_login","$admin_password");

	print "Logged in\r\n";

	$probe->edit_tat_flow_ip_rtp_loss_alarms_rtp_se24( $template, $enable_disable, $new_value );

	print "Done\r\n";
}
else {
	print "Usage: script.pl <probe's IP> <login user> <login password> <add user's name> <add user's password> <add user's group [public|private|admin]>\n\n";
}
