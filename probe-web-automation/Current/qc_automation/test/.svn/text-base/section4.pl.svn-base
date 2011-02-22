#!/usr/bin/perl

use strict;
use lib '/opt/qc_automation';
use QC_WEB;

my $qc = new QC_WEB();

$qc->start_mech( "99.20.184.57", "9090", "root", "public" );

my $xml_data = $qc->get_probe_info( "MAC:0A:37:92" );

my @parsed_values = $qc->probe_parse_all_data( $xml_data );

for( my $i=0; $i<= @parsed_values; $i++){
    print "#".$i . ": " . $parsed_values[$i] . "\n";
}

#print $parsed_values[0] . "\n";
#print $parsed_values[1] . "\n";
#print $parsed_values[2] . "\n";
#print $parsed_values[12] . "\n";
#print $parsed_values[13] . "\n";
#print $parsed_values[4] . "\n";
