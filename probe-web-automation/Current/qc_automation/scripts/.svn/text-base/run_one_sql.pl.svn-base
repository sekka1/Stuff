#!/usr/bin/perl

use strict;
use lib '/opt/qc_automation';
use RUNSQL_SSH;

if( @ARGV == 7 ){

    my $ip = @ARGV[0];
    my $user = @ARGV[1];
    my $pass = @ARGV[2];
    my $sql_user = @ARGV[3];
    my $sql_pass = @ARGV[4];
    my $database = @ARGV[5];
    my $query = @ARGV[6];

    my $sql = new RUNSQL_SSH();

    $sql->start_ssh_session( $ip, $user, $pass );

    $sql->set_sql_creds( $sql_user, $sql_pass );

    $sql->login_to_mysql();

    $sql->run_query( "use " . $database . "\n" );

    $sql->run_query( $query . "\n" );
}
