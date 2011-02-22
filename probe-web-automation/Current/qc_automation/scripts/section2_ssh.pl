#!/usr/bin/perl

use strict;
use lib '/opt/qc_automation';
use QC_SSH;

if( @ARGV == 3 ){

    my $ip = @ARGV[0];
    my $user = @ARGV[1];
    my $pass = @ARGV[2];

    my $qc = new QC_SSH();

    $qc->start_ssh_session( $ip, $user, $pass );

    $qc->section2_check_patch_version();

    $qc->section2_check_iq_services_started();

}
