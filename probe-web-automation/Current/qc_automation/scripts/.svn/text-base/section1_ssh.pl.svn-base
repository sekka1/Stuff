#!/usr/bin/perl

use strict;
use lib '/opt/qc_automation';
use QC_SSH;

if( @ARGV == 3 ){

    my $ip = @ARGV[0];
    my $user = @ARGV[1];
    my $pass = @ARGV[2];

    my $output_json = '[{';

    my $qc = new QC_SSH();

    my $tmp_output = ''; # Use to hold output from calls

    $qc->start_ssh_session( $ip, $user, $pass );


    $tmp_output = $qc->section1_check_version();
    $output_json .= '"os_version":"' . $tmp_output . '",';

    $tmp_output = $qc->section1_check_hd_space();
    $output_json .= '"hd_space":"' . $tmp_output . '",';

    $tmp_output = $qc->section1_check_memory();
    $output_json .= '"memory":"' . $tmp_output . '",';

    $tmp_output = $qc->section1_check_processor();
    $output_json .= '"processor":"' . $tmp_output . '",';

    $tmp_output = $qc->section1_check_mysql();
    $output_json .= '"mysql_version":"' . $tmp_output . '",';

    $tmp_output = $qc->section1_check_required_libs();
    $output_json .= '"required_libs":"' . $tmp_output . '",';

    $tmp_output = $qc->section1_check_java();
    $output_json .= '"java_version":"' . $tmp_output . '",';

    $tmp_output = $qc->section1_check_os_bit();
    $output_json .= '"os_bit":"' . $tmp_output . '",';

    $tmp_output = $qc->section1_check_host_file();
    $output_json .= '"host_file":"' . $tmp_output . '"';

    # Closing json
    $output_json .= '}]';

    print $output_json;
}
