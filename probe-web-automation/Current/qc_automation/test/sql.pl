#!/usr/bin/perl

use strict;
use lib '/opt/qc_automation';
use RUNSQL_SSH;

my $sql = new RUNSQL_SSH();

$sql->start_ssh_session( "72.52.77.132", "root", "^sunshine3" );

$sql->set_sql_creds( "root", "sunshine" );

$sql->login_to_mysql();

$sql->run_query( "show databases;\n" );

$sql->run_query( "use iqcms\n" );

$sql->run_query( "show tables;\n" );
