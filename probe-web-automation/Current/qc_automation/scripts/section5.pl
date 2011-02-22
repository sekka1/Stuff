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

    print "check_reatimeMonitoring_IQAlarms| " . $qc->check_reatimeMonitoring_IQAlarms() . "\n";

    print "check_topology_groups| " . $qc->check_topology_groups() . "\n";

    print "check_topology_views| " . $qc->check_topology_views() . "\n";

}
