#!/usr/bin/perl

use strict;
use lib '/opt/qc_automation';
use QC_WEB;
use JSON;

if( @ARGV == 4 ){

    my $ip = @ARGV[0];
    my $user = @ARGV[1];
    my $pass = @ARGV[2];
    my $webport = @ARGV[3];

    my $qc = new QC_WEB();

    $qc->start_mech( $ip, $webport, $user, $pass );

    my @values = $qc->section2_check_snmp_state( "json" );

# Print out in json
    my $returnJSON = "[";

    for( my $i=0; $i<@values; $i++){

        $returnJSON .= to_json( $values[$i] ) . ",";
    }   

    $returnJSON .= "]";

    $returnJSON =~ s/],]/]]/g;

    print $returnJSON;

    }
