#!/usr/bin/perl

#
# Does one scp command and takes command line arg
#

use strict;

use Expect;

my $direction = @ARGV[0];

my $host = @ARGV[1];
my $username = @ARGV[2];
my $password = @ARGV[3];

my $source = @ARGV[4];
my $destination = @ARGV[5];

my $path_scp = "/usr/bin/scp";

my $command_put = "$path_scp -r $source $username\@$host:$destination\n";
my $command_get = "$path_scp -r $username\@$host:$source $destination\n";

my $exp = new Expect;

$exp->log_file( "/tmp/outputs/output.txt" );

$exp->raw_pty(1);

# Putting local file to remote host
if( $direction =~ /put/ ){

    $exp->spawn( $command_put )
        or die "Cannot spawn $command_put: $!\n";

    $exp->expect( 10, '-re', '^.* password:' );

    $exp->send( "$password\n" );
}

# Get a file from remote host
if( $direction =~ /get/ ){

    $exp->spawn( $command_get )
        or die "Cannot spawn $command_get: $!\n";

    $exp->expect( 10, '-re', '^.* password:' );

    $exp->send( "$password\n" );
}

$exp->soft_close();

