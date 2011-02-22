#!/usr/bin/perl

use strict;
use lib '/opt/qc_automation';
use QC_WEB;
use JSON;

my $qc = new QC_WEB();

$qc->start_mech( "99.20.184.57", "9090", "root", "public" );

my @values = $qc->section2_check_snmp_state( "json" );

print "\n------------Cluster Management State\n";

# Print out the array
#for( my $i=0; $i< @values; $i++ ){

#    print $values[$i][0] . "\n";
#    print $values[$i][1] . "\n";
#    print $values[$i][2] . "\n";
#    print $values[$i][3] . "\n";
#    print $values[$i][4] . "\n";
#    print "---------\n";
#}

# Print out in json
my $returnJSON = "{";

    for( my $i=0; $i<@values; $i++){
    
        $returnJSON .= to_json( $values[$i] ) . ",";
    }   
    
    $returnJSON .= "}";

    $returnJSON =~ s/],}/]}/g; # take off the last comma

print $returnJSON;
