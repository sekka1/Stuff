#!//usr/bin/perl

use strict;

use Expect;

my $path_scp = "/usr/bin/scp";
my $path_scripts = "/home/gkan/qc_scripts";

my $username = 'root';
my $password = '^sunshine3';
my $host = '72.52.77.131';
my $command = "$path_scp -r $path_scripts $username\@$host:/tmp\n";


my $exp = new Expect;

$exp->log_file( "/home/gkan/qc-automation/output.txt" );

$exp->raw_pty(1);

$exp->spawn( $command )
    or die "Cannot spawn $command: $!\n";

$exp->expect( 10, '-re', '^.* password:' );

$exp->send( "$password\n" );

$exp->soft_close();

