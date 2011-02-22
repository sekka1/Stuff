#!/usr/bin/perl

use strict;
use lib '/opt/qc_automation';
use QC_WEB;

my $qc = new QC_WEB();

$qc->start_mech( "99.20.184.57", "9090", "root", "public" );

print "check_reatimeMonitoring_IQAlarms: " . $qc->check_reatimeMonitoring_IQAlarms() . "\n";

print "check_topology_groups: " . $qc->check_topology_groups() . "\n";

print "check_topology_views: " . $qc->check_topology_views() . "\n";
