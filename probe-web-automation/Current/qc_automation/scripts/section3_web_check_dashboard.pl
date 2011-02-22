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

    print "Payload Errors| " . $qc->check_dashboard_payload_error() . "\n";

    print "transport Errors| " . $qc->check_dashboard_transport_error() . "\n";

    print "Payload bar graph| " . $qc->check_dashboard_payload_error_bar_graph() . "\n";

    print "Transport bar graph| " . $qc->check_dashboard_transport_error_bar_graph() . "\n";

    print "Media & System Activities| " . $qc->check_dashboard_activity_window_content() . "\n";

    print "License info| " . $qc->check_version_info() . "\n";

}
