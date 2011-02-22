#!/usr/bin/perl
# vim: set expandtab tabstop=4 shiftwidth=4 softtabstop=4 foldmethod=marker: #

package RUNSQL_SSH;
use strict;
use Expect;

# {{{ new
sub new {
    my $self  = {};

    $self->{ssh} = undef;
    $self->{ip} = undef;
    $self->{user} = undef;
    $self->{password} = undef;
    $self->{sql_user} = undef;
    $self->{sql_pass} = undef;

    $self->{mysql_path} = '/usr/bin/mysql';

    $self->{sql_query} = undef;

    bless($self);
        
    return $self;
}
# }}}
# {{{ start_ssh_session
sub start_ssh_session {
# This allows the class to ssh into the iVMS

    my $self = shift;

    $self->{ip} = $_[0];
    $self->{user} = $_[1];
    $self->{password} = $_[2];

    my $command = "/usr/bin/ssh ".$self->{user}."\@".$self->{ip}."\n";    

    $self->{ssh} = new Expect;

    #$self->{ssh}->raw_pty(1);
    $self->{ssh}->log_stdout(0); # Turn off output the to screen

    # Login to the remote system
    $self->{ssh}->spawn( $command ) 
        or die "Cannot spawn $command: $!\n";
    
    $self->{ssh}->expect( 10, '-re', '^.* password:' );

    $self->{ssh}->send( $self->{password}."\n" );

    $self->{ssh}->expect( 10, '-re', '$\$|$#' );

} 
# }}}
# {{{ set_sql_creds
sub set_sql_creds {

    my $self = shift;

    $self->{sql_user} = $_[0];
    $self->{sql_pass} = $_[1];
}
# }}}
sub login_to_mysql {

    my $self = shift;

    my $cmd = $self->{mysql_path} . " -u " . $self->{sql_user} . " -p" . $self->{sql_pass} . "\n";

    $self->{ssh}->send( $cmd );

    $self->{ssh}->expect( 10, '-re', 'mysql>' );

    my $read = $self->{ssh}->before(); # Grab Output From Command 

    print $read;
}
sub run_query{

    my $self = shift;

    $self->{sql_query} = $_[0];

    $self->{ssh}->send( $self->{sql_query} );

    $self->{ssh}->expect(1); 
                                                                                                                             
    my $read = $self->{ssh}->before(); # Grab Output From Command 

    print $read;
}
1;
