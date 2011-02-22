#!/usr/bin/perl

use strict;
use lib '/opt/qc_automation';
use QC_WEB;

if( @ARGV == 5 ){

    my $ip = @ARGV[0];
    my $user = @ARGV[1];
    my $pass = @ARGV[2];
    my $webport = @ARGV[3];
    my $mac = @ARGV[4];

    my $qc = new QC_WEB();

    $qc->start_mech( $ip, $webport, $user, $pass );

    my $xml_data = $qc->get_probe_info( $mac );

    my @parsed_values = $qc->probe_parse_all_data( $xml_data );

    for( my $i=0; $i<= @parsed_values; $i++){
        #print "#".$i . ": " . $parsed_values[$i] . "\n";
        print $parsed_values[$i] . "||";
    }
    
    print "\n";

#print $parsed_values[0] . "\n";
#print $parsed_values[1] . "\n";
#print $parsed_values[2] . "\n";
#print $parsed_values[12] . "\n";
#print $parsed_values[13] . "\n";
#print $parsed_values[4] . "\n";
}
