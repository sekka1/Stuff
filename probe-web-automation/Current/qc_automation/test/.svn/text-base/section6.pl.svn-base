#!/usr/bin/perl

use strict;
use lib '/opt/qc_automation';
use QC_WEB;

my $qc = new QC_WEB();

$qc->start_mech( "99.20.184.57", "9090", "root", "public" );

print "check_monitor_group_type: " . $qc->check_monitor_group_type() . "\n";
print "check_monitor_monitor_groups: " . $qc->check_monitor_monitor_groups() . "\n";
print $qc->get_license_info();
