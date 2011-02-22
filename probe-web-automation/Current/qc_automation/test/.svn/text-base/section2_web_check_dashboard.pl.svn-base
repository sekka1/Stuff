#!/usr/bin/perl

use strict;
use lib '/opt/qc_automation';
use QC_WEB;

my $qc = new QC_WEB();

$qc->start_mech( "72.52.77.131", "9090", "root", "public" );

my @values = $qc->section2_check_snmp_state();

print "------------Cluster Management State\n";

for( my $i=0; $i< @values; $i++ ){

    print $values[$i][0] . "\n";
    print $values[$i][1] . "\n";
    print $values[$i][2] . "\n";
    print $values[$i][3] . "\n";
    print $values[$i][4] . "\n";
    print "---------\n";
}
