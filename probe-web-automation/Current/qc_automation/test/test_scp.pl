#!//usr/bin/perl

use strict;

use Net::SCP;

my $hostname = '72.52.77.131';
my $username = 'root';

my $scp = Net::SCP->new( $hostname, $username );

$scp->put( "/home/gkan/qc-automation/test-file.txt" ) or die $scp->{errstr};

