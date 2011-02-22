#!/usr/bin/perl
# vim: set expandtab tabstop=4 shiftwidth=4 softtabstop=4 foldmethod=marker: #

package QC_SSH;
use strict;
use Expect;

# {{{ new
sub new {
    my $self  = {};

    $self->{ssh} = undef;
    $self->{ip} = undef;
    $self->{user} = undef;
    $self->{password} = undef;

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
# {{{ remove_unwanted_chars
sub remove_unwanted_chars {

    my $self = shift;

    my $data = $_[0];

    # Replace carriage returns with <br/>
    $data =~ s/\r|\n/<br\/>/g;

    # Remove double quotes 
    $data =~ s/"//g;

    # Remove white space from front and end of string
    $data =~ s/^\s+//;
    $data =~ s/\s+$//;

    return $data;
}
# }}}
# {{{ section1_check_version
sub section1_check_version{

    my $self = shift;
    
    $self->{ssh}->send( "cat /etc/redhat-release \n" );
    
    $self->{ssh}->expect(1);
    
    my $read = $self->{ssh}->before(); # Grab Output From Command

    # Clear the ssh content
    $self->{ssh}->clear_accum();
    
    return $self->remove_unwanted_chars( $read );
}
# }}}
# {{{ section1_check_hd_space
sub section1_check_hd_space{

    my $self = shift;

    $self->{ssh}->send( "df -kh \n" );

    $self->{ssh}->expect(1);

    my $read = $self->{ssh}->before(); # Grab Output From Command

    # Clear the ssh content
    $self->{ssh}->clear_accum();

    return $self->remove_unwanted_chars( $read );
}
# }}}
# {{{ section1_check_memory
sub section1_check_memory{

    my $self = shift;

    $self->{ssh}->send( "cat /proc/meminfo \n" );

    $self->{ssh}->expect(1);
    
    my $read = $self->{ssh}->before(); # Grab Output From Command

    # Clear the ssh content
    $self->{ssh}->clear_accum();

    return $self->remove_unwanted_chars( $read );
}
# }}}
# {{{ section1_check_processor
sub section1_check_processor{

    my $self = shift;

    $self->{ssh}->send( "cat /proc/cpuinfo \n" );

    $self->{ssh}->expect(1);

    my $read = $self->{ssh}->before(); # Grab Output From Command

    # Clear the ssh content
    $self->{ssh}->clear_accum();
    
    return $self->remove_unwanted_chars( $read );
}
# }}}
# {{{ section1_check_mysql
sub section1_check_mysql{

    my $self = shift;

    $self->{ssh}->send( "/usr/bin/mysql -V \n" );

    $self->{ssh}->expect(1);                                                                                
    
    my $read = $self->{ssh}->before(); # Grab Output From Command                                           

    # Clear the ssh content
    $self->{ssh}->clear_accum();

    return $self->remove_unwanted_chars( $read );
}
# }}}
# {{{ section1_check_required_libs
sub section1_check_required_libs{

    my $self = shift;

    $self->{ssh}->send( "rpm -qa | grep -i -e libxp -e db4-devel \n" );

    $self->{ssh}->expect(10);                                                                                
    
    my $read = $self->{ssh}->before(); # Grab Output From Command                                           

    # Clear the ssh content
    $self->{ssh}->clear_accum();

    return $self->remove_unwanted_chars( $read );
}
# }}}
# {{{ section1_check_java
sub section1_check_java{

    my $self = shift;

    #$self->{ssh}->send( "/usr/bin/java -version \n" );
    $self->{ssh}->send( "/opt/ineoquest/ivms-4.02.00.093/jre/bin/java -version \n" );

    $self->{ssh}->expect(1);

    my $read = $self->{ssh}->before(); # Grab Output From Command                                           

    # Clear the ssh content
    $self->{ssh}->clear_accum();

    return $self->remove_unwanted_chars( $read );
}
# }}}
# {{{ section1_check_os_bit
sub section1_check_os_bit{

    my $self = shift;

    $self->{ssh}->send( "/usr/bin/getconf LONG_BIT \n" );

    $self->{ssh}->expect(1);                                                                                

    my $read = $self->{ssh}->before(); # Grab Output From Command                                           

    # Clear the ssh content
    $self->{ssh}->clear_accum();

    return $self->remove_unwanted_chars( $read );
}
# }}}
# {{{ section1_check_host_file
sub section1_check_host_file{

    my $self = shift;

    $self->{ssh}->send( "cat /etc/hosts \n" );

    $self->{ssh}->expect(1);                                                                                

    my $read = $self->{ssh}->before(); # Grab Output From Command                                           

    # Clear the ssh content
    $self->{ssh}->clear_accum();

    return $self->remove_unwanted_chars( $read );
}
# }}}
# {{{ section2_check_patch_version
sub section2_check_patch_version {

    my $self = shift;

    $self->{ssh}->send( "cat /opt/ineoquest/ivms-default/version.txt \n" );

    $self->{ssh}->expect(1);

    my $read = $self->{ssh}->before(); # Grab Output From Command

    print $read;
}
# }}}
# {{{ section2_check_iq_services_started
sub section2_check_iq_services_started {

    my $self = shift;

    $self->{ssh}->send( "/etc/init.d/ivms-all status \n" );

    $self->{ssh}->expect(10);

    my $read = $self->{ssh}->before(); # Grab Output From Command

    print $read;
}
# }}}
# {{{ section2_check_xml_check_external_address
sub section2_check_xml_check_external_address{

    my $self = shift;                                                                   
                                                                                        
    $self->{ssh}->send( "cat /opt/ineoquest/ivms-default/ineoQuestNMS/conf/IQGuardianSettings.xml | grep \"server_config\" \n" );                             
                                                                                        
    $self->{ssh}->expect(10);                                                           

    my $read = $self->{ssh}->before(); # Grab Output From Command                       
    
    print $read;
}
# }}}
# {{{ section2_check_xml_smtp_config
sub section2_check_xml_smtp_config{

    my $self = shift;
 
    $self->{ssh}->send( "cat /opt/ineoquest/ivms-default/ineoQuestNMS/conf/IQGuardianSettings.xml | grep \"smtp_server smtpServer\" \n" );

    $self->{ssh}->expect(10);

    my $read = $self->{ssh}->before(); # Grab Output From Command                       

    print $read;
}
# }}}
# {{{ section2_get_retentionPeriod
sub section2_get_retentionPeriod{

    my $self = shift;
 
    $self->{ssh}->send( "cat /opt/ineoquest/ivms-default/ineoQuestNMS/conf/IQDBPurgeSettings.xml | grep \"retentionPeriod\" \n" );

    $self->{ssh}->expect(10);

    my $read = $self->{ssh}->before(); # Grab Output From Command                       

    print $read;
}
# }}}
# {{{ section2_get_snmpCommunityString
sub section2_get_snmpCommunityString{

    my $self = shift;
 
    $self->{ssh}->send( "cat /opt/ineoquest/ivms-default/ineoQuestNMS/conf/snmpParameter.xml | grep readCommunity" );

    $self->{ssh}->expect(10);

    my $read = $self->{ssh}->before(); # Grab Output From Command                       

    print $read;
}
# }}}
1;
