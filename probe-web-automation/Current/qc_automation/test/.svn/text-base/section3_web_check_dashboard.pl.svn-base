#!/usr/bin/perl

use strict;
use lib '/opt/qc_automation';
use QC_WEB;

my $qc = new QC_WEB();

$qc->start_mech( "99.20.184.57", "9090", "root", "public" );

print "Payload Errors: " . $qc->check_dashboard_payload_error() . "\n";

print "transport Errors: " . $qc->check_dashboard_transport_error() . "\n";

print "Payload bar graph: " . $qc->check_dashboard_payload_error_bar_graph() . "\n";

print "Transport bar graph: " . $qc->check_dashboard_transport_error_bar_graph() . "\n";

print "Media & System Activities: " . $qc->check_dashboard_activity_window_content() . "\n";

print "License info: " . $qc->check_version_info() . "\n";
