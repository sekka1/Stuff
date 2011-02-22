#!/usr/bin/perl

use strict;
use lib '/opt/qc_automation';
use QC_SSH;

my $qc = new QC_SSH();

$qc->start_ssh_session( "72.52.77.131", "root", "sunshine" );

$qc->section2_check_patch_version();

$qc->section2_check_iq_services_started();
