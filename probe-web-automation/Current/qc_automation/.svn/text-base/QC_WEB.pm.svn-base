#!/usr/bin/perl
# vim: set expandtab tabstop=4 shiftwidth=4 softtabstop=4 foldmethod=marker: #

#
# This class goes into the iVMS web page to perform QC automation
# It uses the IVMS module
#

package QC_WEB;
use lib '/opt/probe-web-automation';
use strict;
use Expect;
use IVMS;
use JSON;

# {{{ new
sub new {
    my $self  = {};

    $self->{ivms} = undef;

    $self->{ip} = undef;
    $self->{port} = undef;
    $self->{user} = undef;
    $self->{password} = undef;

    bless($self);
        
    return $self;
}
# }}}
# {{{ start_mech
sub start_mech{

    my $self = shift;

    $self->{ip} = $_[0];
    $self->{port} = $_[1];
    $self->{user} = $_[2];
    $self->{password} = $_[3];

    $self->{ivms} = IVMS->new();

    $self->{ivms}->set_page_ip( $self->{ip}, $self->{port} );

    $self->{ivms}->start_mech();

    $self->{ivms}->login( $self->{user}, $self->{password} );

}
# }}}
# {{{ section2_check_snmp_state
sub section2_check_snmp_state{
# Returns a 2D array of the stuff in iVMS->Configuration->Cluster Management page
# First D is the probe
# The second D holds the information for each prob
# 0 = mac, 1 = node_type, 2 = monitor_ip, 3 = comm_state, 4 = probe_state

    my $self = shift;

    my $result_format = $_[0]; # json, array

    # Return array with all the variables
    my @returnArray = undef;

    my $content = $self->{ivms}->get_configuration_clusterManagement();

    # This will get all the probes information except for the State
    # Information such as name, mac, IP, comm type
    my @matches1 = ( $content =~ /class="iqdataborder">(.*)(?:.<\/th>|<\/td>)/g );

    #print @matches1 . "\n";

    my $track_count = -1; # Tracks information for each probe
    my $probe_track = -1; # Tracks the probe number we are on currently
    my $did_set = 0; # Track if we set a value or not.  This will be used to increment the $track_count

    for( my $i=0; $i < @matches1; $i++){

        #print $matches1[$i] . "\n";

        if( $matches1[$i] =~ /^MAC/ ){
            # This is a begining line of a probes information
            $track_count = 0;
            $probe_track++;
        }

        my $temp = $matches1[$i];

        if( $track_count == 0 ) { $returnArray[$probe_track][0] = $self->remove_unwanted_chars( $matches1[$i] ); $did_set = 1; } # mac
        if( $track_count == 1 ) { $returnArray[$probe_track][1] = $self->remove_unwanted_chars( $matches1[$i] ); $did_set = 1; } # node_type
        if( $track_count == 2 ) { $returnArray[$probe_track][2] = $self->remove_unwanted_chars( $matches1[$i] ); $did_set = 1; } # monitor_ip
        if( $track_count == 3 ) { $returnArray[$probe_track][3] = $self->remove_unwanted_chars( $matches1[$i] ); $did_set = 1; } # comm_state
    
        if( $did_set == 1 ) { $track_count++; $did_set = 0; };
    }

    # This will get the probe state.  Then we will match it back up with the
    # information in the previous regex
    my @matches2 = ( $content =~ /<span style=".*">(.*)<\/span>/g );

    #print @matches2 . "\n";
    
    for( my $i=0; $i < @matches2; $i++){
    
        #print $matches2[$i] . "\n";

        $returnArray[$i][4] = $matches2[$i]; # probe_state
    }

    return @returnArray;
}
# }}}
# {{{ convert_to_json
sub convert_to_json{
# Takes in a 2D array and converts it into JSON format

# BROKEN: For somereason when passing in a 2D array it only
# sees one of the first array

    my $self = shift;

    my @data = $_[0];

    my $returnJSON = "{";

    for( my $i=0; $i<@data; $i++){

        $returnJSON .= to_json( $data[$i] ) . ",";
    }

    $returnJSON .= "}";

    $returnJSON =~ s/],}/]}/g; # take off the last comma


    return $returnJSON;
}
# }}}
# {{{ remove_unwanted_chars
sub remove_unwanted_chars {

    my $self = shift;

    my $data = $_[0];

    $data =~ s/&nbsp;//g;

    $data =~ s/<a href=.*">//g;

    $data =~ s/<\/a>//g;
 
    # Remove white space from front and end of string
    $data =~ s/^\s+//;
    $data =~ s/\s+$//;

    return $data;
}
# }}}
# {{{ is_page_not_found
sub is_page_not_found{
# Searches for the words "404 Not Found" and returns
# true or false

    my $self = shift;

    my $content = $_[0];

    my $returnVal = 0;

    my @matches = ( $content =~ /404 Not Found/g );

    if( @matches > 0 ){
        $returnVal = 1;
    }

    return $returnVal;
}
# }}}
# {{{ check_dashboard_payload_error
sub check_dashboard_payload_error{
# Checks the dashboard's payload error data.  Grabs data from that url

# Returns: -1 = page not found, 0 = no data, 1 - good

    my $self = shift;

    my $url_path = "/IQHDProgList.do?listSize=20";

    my $returnVal = 0;

    my $url_header = "http://" . $self->{ip} . ":" . $self->{port};

    my $content = $self->{ivms}->get_url( $url_header . $url_path );

    if( $self->is_page_not_found( $content ) ){
        $returnVal = -1;
    }
    if( $content =~ /pr|ID|PD|SD/g ){
        $returnVal = 1;
    }

    return $returnVal;
}
# }}}
# {{{ check_dashboard_transport_error
sub check_dashboard_transport_error{

    my $self = shift;

    my $url_path = "/IQHDTranList.do?listSize=20";

    my $returnVal = 0;

    my $url_header = "http://" . $self->{ip} . ":" . $self->{port};

    my $content = $self->{ivms}->get_url( $url_header . $url_path );

    if( $self->is_page_not_found( $content ) ){
        $returnVal = -1;
    }
    if( $content =~ /N|IH|PH|SH|ID/g ){
        $returnVal = 1;
    }

    return $returnVal;
}
# }}}
# {{{ check_dashboard_payload_error_bar_graph
sub check_dashboard_payload_error_bar_graph{
# Will just check if the link is in the data that is returned
# for the ajax to go and get it.

    my $self = shift;

    my $url_path = "/IQHDTrends.do?chartHeight=175&chartWidth=345&showLegend=false&maxAxis=250&paydata=EI&trandata=EI&chart=cylinder";

    my $returnVal = 0;

    my $url_header = "http://" . $self->{ip} . ":" . $self->{port};

    my $content = $self->{ivms}->get_url( $url_header . $url_path );

    if( $self->is_page_not_found( $content ) ){
        $returnVal = -1;
    }
    if( $content =~ /pherr>\/ineoQuestNMS/g ){
        $returnVal = 1;
    }

    return $returnVal;
}
# }}}
# {{{ check_dashboard_transport_error_bar_graph
sub check_dashboard_transport_error_bar_graph{
    
    my $self = shift;

    my $url_path = "/IQHDTrends.do?chartHeight=175&chartWidth=345&showLegend=false&maxAxis=250&paydata=EI&trandata=EI&chart=cylinder";

    my $returnVal = 0;
                                                                                                               
    my $url_header = "http://" . $self->{ip} . ":" . $self->{port};                                            

    my $content = $self->{ivms}->get_url( $url_header . $url_path );                                           
                                                                                                               
    if( $self->is_page_not_found( $content ) ){                                                                
        $returnVal = -1;                                                                                       
    }
    if( $content =~ /trans>\/ineoQuestNMS/g ){
        $returnVal = 1;
    }

    return $returnVal;
}
# }}}
# {{{ check_dashboard_activity_window_content
sub check_dashboard_activity_window_content{
# Checks the Media Activities and System Activites tab on the dashboard
# For some content

    my $self = shift;

    my $url_path = "/IQBasketList.do";

    my $returnVal = 0;

    my $url_header = "http://" . $self->{ip} . ":" . $self->{port};

    my $content = $self->{ivms}->get_url( $url_header . $url_path );

    if( $self->is_page_not_found( $content ) ){
        $returnVal = -1;
    }
    # Check if the content has any of the keywords in it that can tell us
    # there is something in there
    if( $content =~ /instance|lstate|Affected|Video|Audio|MLS|MLT|point/g ){
        $returnVal = 1;
    }

    return $returnVal;
}
# }}}
# {{{ check_version_info
sub check_version_info{
# Takes the version info from the web page.

    my $self = shift;

    my $url_path = "/admin/versionhistory.do";

    my $returnVal = 0;
    
    my $url_header = "http://" . $self->{ip} . ":" . $self->{port};                                            

    my $content = $self->{ivms}->get_url( $url_header . $url_path );

    my @matches = ( $content =~ /TD class="iqdataborder_bold" nowrap>(.*)<\/TD>|class="iqdataborder" nowrap><b>(.*)<\/b>/g );

    my $license_type = 'License Type:' . $self->remove_unwanted_chars( $matches[3] );
    my $version = 'version:' . $self->remove_unwanted_chars( $matches[6] );
    my $install_date = 'install date:' . $self->remove_unwanted_chars( $matches[8] );
    my $s_no = 'S. No:' . $self->remove_unwanted_chars( $matches[4] );

    $returnVal = $license_type . "," . $version . "," . $install_date . "," . $s_no;

#    for( my $i =0; $i < @matches; $i++ ){

#        print $self->remove_unwanted_chars( $matches[$i] ) . "\n";
#    }    

    return $returnVal;
}
# }}}
# {{{ get_probe_info
sub get_probe_info{
# This is the probe information from Realtime Monitoring->IQ List and then clicking on the probes name
# This popup displays the vital info about a probe

# This function only gets the information (xml) format and it lets the other functions to parse out
# which particular item you want from there.

# Need to pass in a MAC Address, in this format: MAC:0A:37:92

    my $self = shift;

    my $mac = $_[0];

    my $url_path = "/servlet/IQReportServlet?action=getProbeStats&monitor=" . $mac;

    my $returnVal = 0;

    my $url_header = "http://" . $self->{ip} . ":" . $self->{port};

    my $content = $self->{ivms}->get_url( $url_header . $url_path );

    if( $self->is_page_not_found( $content ) ){
        $returnVal = -1;
    } else {
        $returnVal = $content;
    }

    return $returnVal;
}
# }}}
# {{{ probe_parse_all_data
sub probe_parse_all_data{
# This function expects the xml output from the "get_probe_info" function here.
# It will return an array with all the variable

# INPUT: xml string from the get_probe_info
# Returns: an array
# 0 = probe name, 1 = primary VMS, 
# 2 = secondary VMS, 3 = DataCube IP, 4 = Communication Uptime
# 3 = Front port Link Status, 4 = Management Port Link Configuration
# 4 = Management Port Negotiated Link Speed, 5 = Time Diff
# 6 = probe time, 7 = firmware version, 8 = expected version
# 9 = unsaved config, 10 = Alarm Configuration
# 11 = perfomance data proc, 12 = probe type, 13 = probe IP

    my $self = shift;

    my $xml_data = $_[0];

    my @returnArray = undef;

    if( $xml_data =~ m/<nm><val>(.*)<\/val><\/nm>/g ){ $returnArray[0] = $1; }         
    if( $xml_data =~ m/<vp><val>(.*)<\/val><\/vp>/g ){ $returnArray[1] = $1; }
    if( $xml_data =~ m/<vs><val>(.*)<\/val><\/vs>/g ){ $returnArray[2] = $1; }
    if( $xml_data =~ m/<fpl><val>(.*)<\/val><als>1<\/als><\/fpl>/g ){ $returnArray[3] = $1; }
    if( $xml_data =~ m/<iqs><val>(.*)<\/val><als>.*<\/als><\/iqs>/g ){ $returnArray[4] = $1; }
    if( $xml_data =~ m/<mpc><val>(.*)<\/val><als>1<\/als><\/mpc>/g ){ $returnArray[4] = $1; }
    if( $xml_data =~ m/<mpt><val>(.*)<\/val><\/mpt>/g ){ $returnArray[5] = $1; }
    if( $xml_data =~ m/<syst><val>(.*)<\/val><\/syst>/g ){ $returnArray[6] = $1; }
    if( $xml_data =~ m/<v><val>(.*)<\/val><als>1<\/als><\/v>/g ){ $returnArray[7] = $1; }
    if( $xml_data =~ m/<ve><val>(.*)<\/val><\/ve>/g ){ $returnArray[8] = $1; }
    if( $xml_data =~ m/<usc><val>(.*)<\/val><als>3<\/als><\/usc>/g ){ $returnArray[9] = $1; }
    if( $xml_data =~ m/<acc><val>(.*)<\/val><\/acc>/g ){ $returnArray[10] = $1; }
    # if( $xml_data =~ m//g ){ $returnArray[11] = $1; }
    if( $xml_data =~ m/<type><val>(.*)<\/val><\/type>/g ){ $returnArray[12] = $1; }
    if( $xml_data =~ m/<ip><val>(.*)<\/val><\/ip>/g ){ $returnArray[13] = $1; }

    return @returnArray;
}
# }}}
# {{{ check_reatimeMonitoring_IQAlarms
sub check_reatimeMonitoring_IQAlarms{
# Checks the Realtime Monitoring->IQ Alarms page to see if it is populating
# with data.  It will look for a few keywords in the json data that is return

    my $self = shift;

    my $url_path = "/IQBasketList.do?basketType=0";

    my $returnVal = 0;

    my $url_header = "http://" . $self->{ip} . ":" . $self->{port};

    my $content = $self->{ivms}->get_url( $url_header . $url_path );

    if( $self->is_page_not_found( $content ) ){
        $returnVal = -1;
    }
    # Check if the content has any of the keywords in it that can tell us
    # there is something in there
    if( $content =~ /VIDEO|BUFFER|Alarmed|Affected|MLS|Monitoring/g ){
        $returnVal = 1;
    }

    return $returnVal;
}
# }}}
# {{{ check_topology_groups
sub check_topology_groups{
# Checks the Configuration->Topology View Configuration->IQ Topology Groups page
# It just checks if there is a group configured in there

    my $self = shift;

    my $url_path = "/map/IQTopoGroupConfig.do?selectedTab=Configuration&viewId=IQTopoGroupConfig&displayName=IQ+Topo+Groups&swipe=true&nodeClicked=IQTopoGroupConfig&selectedNode=IQTopoGroupConfig";

    my $returnVal = 0;

    my $url_header = "http://" . $self->{ip} . ":" . $self->{port};

    my $content = $self->{ivms}->get_url( $url_header . $url_path );

    if( $self->is_page_not_found( $content ) ){
        $returnVal = -1;
    }
    # Check if the content has any of the keywords in it that can tell us
    # there is something in there
    if( $content =~ /Update Group|Delete Group/g ){
        $returnVal = 1;
    }

    return $returnVal;
}
# }}}
# {{{ check_topology_views
sub check_topology_views{
# Checks the Configuration->Topology View Configuration->IQ Topology View page
# It just checks if there is a view configured in there

    my $self = shift;
    my $url_path = "/map/IQTopoViewConfig.do?selectedTab=Configuration&viewId=IQTopoViewConfig&displayName=IQ+Topo+Views&swipe=true&nodeClicked=IQTopoViewConfig&selectedNode=IQTopoViewConfig";

    my $returnVal = 0;

    my $url_header = "http://" . $self->{ip} . ":" . $self->{port};

    my $content = $self->{ivms}->get_url( $url_header . $url_path );

    if( $self->is_page_not_found( $content ) ){
        $returnVal = -1;
    }
    # Check if the content has any of the keywords in it that can tell us
    # there is something in there    
    if( $content =~ /Update View|Delete View/g ){
        $returnVal = 1;                                                                                                            
    }

    return $returnVal;
}
# }}}
# {{{ check_monitor_group_type
sub check_monitor_group_type{
# Checks the Configuration->Monitor Group Configuration->Group Type page                                                      
# It just checks if there is a something configured in there

    my $self = shift;                                                                                                               
    my $url_path = "/map/IQMonitorGroupTypeConfig.do?selectedTab=Configuration&viewId=IQMonitorGroupTypeConfig&displayName=Group+Types&swipe=true&nodeClicked=IQMonitorGroupTypeConfig&selectedNode=IQMonitorGroupTypeConfig";
                                                                                                                                    
    my $returnVal = 0;                                                                                                              
                                                                                                                                    
    my $url_header = "http://" . $self->{ip} . ":" . $self->{port};                                                                 
                                                                                                                                    
    my $content = $self->{ivms}->get_url( $url_header . $url_path );                                                                
                                                                                                                                    
    if( $self->is_page_not_found( $content ) ){                                                                                     
        $returnVal = -1;                                                                                                            
    }                                                                                                                               
    # Check if the content has any of the keywords in it that can tell us                                                           
    # there is something in there                                                                                                   
    if( $content =~ /Update Group|Delete Group/g ){                                                                                   
        $returnVal = 1;                                                                                                             
    }                                                                                                                               
                                                                                                                                    
    return $returnVal;
    
}
# }}}
# {{{ check_monitor_monitor_groups
sub check_monitor_monitor_groups{
# Checks the Configuration->Monitor Group Configuration->Monitor Group page                                                      
# It just checks if there is a something configured in there

    my $self = shift;
    my $url_path = "/map/IQMonitorGroupConfig.do?selectedTab=Configuration&viewId=IQMonitorGroupConfig&displayName=Group+Types&swipe=true&nodeClicked=IQMonitorGroupConfig&selectedNode=IQMonitorGroupConfig";

    my $returnVal = 0;

    my $url_header = "http://" . $self->{ip} . ":" . $self->{port};

    my $content = $self->{ivms}->get_url( $url_header . $url_path );

    if( $self->is_page_not_found( $content ) ){
        $returnVal = -1;
    }
    # Check if the content has any of the keywords in it that can tell us                                                           
    # there is something in there                                                                                                   
    if( $content =~ /Update Monitor|Delete Monitor/g ){  
        $returnVal = 1;
    }

    return $returnVal;
}
# }}}
# {{{ get_license_info
sub get_license_info{
# Retreives values from the Configuration->Inventory / Licensing Status page

    my $self = shift;

    my $returnVal = '';

    my $url_path = "/admin/IQLicensePage.do?selectedTab=Configuration&viewId=LicensingDetails&displayName=Inventory+%2F+Licensing+Status&firstChild=false&swipe=true&nodeClicked=LicensingDetails&selectedNode=LicensingDetails";

    my $url_header = "http://" . $self->{ip} . ":" . $self->{port};

    my $content = $self->{ivms}->get_url( $url_header . $url_path );

    # This will get all the license information 
    my @matches1 = ( $content =~ /11px;font-weight: bold">(.*)<\/span><\/td>/g );

    $returnVal .= '[';

    for( my $i=0; $i < @matches1; $i++){

        $returnVal .= '{"' . $matches1[$i] . '":"' . $matches1[$i+1] . '"},';

        $i++;
    }

    $returnVal .= ']';

    return $returnVal;
}
# }}}
1;
