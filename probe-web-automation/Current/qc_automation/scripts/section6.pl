#!/usr/bin/perl

use strict;
use lib '/opt/qc_automation';
use QC_WEB;

if( @ARGV == 4 ){

    my $ip = @ARGV[0];
    my $user = @ARGV[1];
    my $pass = @ARGV[2];
    my $webport = @ARGV[3];

my $qc = new QC_WEB();

$qc->start_mech( $ip, $webport, $user, $pass );

print "check_monitor_group_type| " . $qc->check_monitor_group_type() . "\n";
print "check_monitor_monitor_groups| " . $qc->check_monitor_monitor_groups() . "\n";
print "license_info| " . $qc->get_license_info();

}
