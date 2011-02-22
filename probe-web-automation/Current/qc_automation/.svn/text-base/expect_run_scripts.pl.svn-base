#!/usr/bin/perl

use strict;

use Expect;

my $username = @ARGV[0];
my $password = @ARGV[1];
my $host = @ARGV[2];

# Scripts paths and names to put on the remote system
my $script_path = '/tmp/qc_scripts/';
my $output_dir = '/tmp/';
my $script_ivms_check = 'iVMS_Check.sh';
my $script_ivms_check_output = 'ivms_check_out.txt';
my $script_rh_hardware = 'RH-Hdware.sh';
my $script_rh_hardware_out = 'sys-output';

# Local systems script paths
my $push_qc_scripts = '/opt/qc_scripts/';
my $qc_auto_script_location = '/opt/qc_automation/';
my $expect_scp_script = $qc_auto_script_location."expect_scp.pl";
my $retrieve_script_location = '/tmp/outputs/';

##############################################
##############################################

#
# Copy QC scripts over to the remote computer
#

my $put_command = $expect_scp_script." put '$host' '$username' '$password' '$push_qc_scripts' '$output_dir'";
print $put_command . "\n";
`$put_command`;

#
# Run the QC scripts
#    

my $command = "/usr/bin/ssh $username\@$host\n";

my $exp = new Expect;

#$exp->log_file( "/home/gkan/qc-automation/output.txt" );

$exp->raw_pty(1);

# Login to the remote system
$exp->spawn( $command )
    or die "Cannot spawn $command: $!\n";

$exp->expect( 10, '-re', '^.* password:' );

$exp->send( "$password\n" );

# Run the first script
$exp->send( "$script_path$script_ivms_check > $output_dir$script_ivms_check_output\n" );

$exp->expect( 15, '-re', '$#' );

# Run the second script
$exp->send( "$script_path$script_rh_hardware > $output_dir$script_rh_hardware_out \n" );

$exp->expect( 15, '-re', '$#' );

$exp->send( "exit\n" );

$exp->soft_close();

#
# Copy output files back to this server
#

# Copy ivms_check_out.txt
my $get_command = $expect_scp_script." get '$host' '$username' '$password' '$output_dir$script_ivms_check_output' '$retrieve_script_location'";

`$get_command`;

# Copy rh_hardware_output.txt
$get_command = $expect_scp_script." get '$host' '$username' '$password' '$output_dir$script_rh_hardware_out' '$retrieve_script_location'";

`$get_command`;

