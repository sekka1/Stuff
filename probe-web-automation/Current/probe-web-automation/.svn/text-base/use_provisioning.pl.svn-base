#!/usr/bin/perl

use strict;
use lib '/opt/probe-web-automation';
use Provisioning;

my $provisioning = Provisioning->new( '/tmp/config2.txt', 'Admin', 'Su' );

$provisioning->open_file();

$provisioning->probe_list( 'gkan.webhop.net' );

$provisioning->parse_file();
