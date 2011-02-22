#!/usr/bin/perl
# vim: set expandtab tabstop=4 shiftwidth=4 softtabstop=4 foldmethod=marker: #

package IQ;
use strict;
use WWW::Mechanize;
use HTTP::Cookies;
#use XML::Parser;
#use XML::SimpleObject;
use Switch;
use LWP 5.64;
use Digest::MD5;

# {{{ new
sub new {
        my $self  = {};

	$self->{PAGE_IP} = undef;
    $self->{mech} = undef;

        bless($self);
        return $self;
}
# }}}
# {{{ start_mech
sub start_mech {

    my $self = shift;

    my $mech = WWW::Mechanize->new( autocheck => 1 );

    $mech->agent => "Mozilla/4.0 (compatible; MSIE 6.0; Windows NT 5.1)";

    $mech->cookie_jar( {} );    # an empty, memory-only HTTP::Cookies object

    $self->{mech} = $mech;
}
# }}}
# {{{ get_mech
sub get_mech {

    my $self = shift;

    return $self->{mech};

}
# }}}
# {{{ set_nsp_ip
sub set_page_ip {

	my $self = shift;

	$self->{PAGE_IP} = $_[0];	
}
# }}}
# {{{ login
sub login {

	my $self = shift;

    my $username = $_[0];
    my $password = $_[1];

    $self->{mech}->get( "http://".$self->{PAGE_IP}."/" );

    my $page_content = $self->{mech}->content;

    # Login page hashes the password and combining it with a nounce before posting
    # it to the server in this format:  <User Name>:<Password>:<Nounce>
    $page_content =~ /name="nonce" value="(.*)">/g;

    my $nounce = $1;

    my $encoded_string = Digest::MD5::md5_hex( $username . ':' . $password . ':' . $nounce );

    $self->{mech}->post( "http://".$self->{PAGE_IP}."/",
                            [
                                'URL' => 'GET:/fs/index.htm',
                                'argList' => 'REMOTE_ADDR=192.168.1.28 SERVER_SOFTWARE=INEOQUEST/2.0 SERVER_NAME=IQ Cricket SERVER_PROTOCOL=HTTP/1.1 SERVER_PORT=80 REQUEST_METHOD=GET PATH_INFO=/ HOST= 192.168.1.106 ACCEPT_ENCODING=gzip,deflate END_OF_HEADERS=',
                                'encoded' => 'Admin:' . $encoded_string,
                                'mimeHeaderList' => 'Content-Encoding=gzip',
                                'nonce' => $nounce
                            ],
                        );
}
# }}}
# {{{ add_user
sub add_user {
# Adds a user into a probe

        my $self = shift;

        my $add_users_name = $_[0];
        my $add_users_password = $_[1];
        my $add_users_access_level = $_[2];

        my $access_level_map_number = -1;

        if( $add_users_access_level =~ /public/ ){
            $access_level_map_number = 0;
        }
        if( $add_users_access_level =~ /private/ ){
            $access_level_map_number = 1;
        }
        if( $add_users_access_level =~ /admin/ ){
            $access_level_map_number = 2;
        }

        $self->{mech}->get("http://".$self->{PAGE_IP}."/security/userconfig.html");
        $self->{mech}->get("http://".$self->{PAGE_IP}."/security/userconfig.html?account_list=0&userName=".$add_users_name."&password=".$add_users_password."&access_level=$access_level_map_number&account_submit=Add+User");
}
# }}}
# {{{ delete_user
sub delete_user {
# Delete a user on the probe

    my $self = shift;

    my $user_to_delete = $_[0];
    my $add_users_access_level = $_[1];

    # Look for the user mapping to the <account_list> var that will get passed into
    # the GET delete URL
    $self->{mech}->get( "http://".$self->{PAGE_IP}."/security/userconfig.html" );

    my $page_content = $self->{mech}->content;

    $page_content =~ /<option value="(.*)"  >$user_to_delete,/g;

    my $account_list_map = $1;

    # Get the access level mapping
    my $access_level_map_number = -1;

        if( $add_users_access_level =~ /public/ ){
            $access_level_map_number = 0;
        }
        if( $add_users_access_level =~ /private/ ){
            $access_level_map_number = 1;
        }
        if( $add_users_access_level =~ /admin/ ){
            $access_level_map_number = 2;
        }

    $self->{mech}->get("http://".$self->{PAGE_IP}."/security/userconfig.html?account_list=".$account_list_map."&account_submit=Delete+User&userName=&password=&access_level=".$access_level_map_number);

}
# }}}
# {{{ change_admins_password
sub change_admins_password {
# Changes the admins password.  Since there is no password change utility in the web interface,
# this function is here to facilitate that piece.  It will first create a temp user with admin priv,
# then delete the "Admin" user, then create an Admin user with the new password, and then delte the
#temp admin user.

    my $self = shift;
    
    my $new_admins_password = $_[0];

    # Add temp user with admin priv
    $self->add_user( 'tempadmin', 'Sunsh1ne!90', 'admin' );

    # delete the "Admin" user
    $self->delete_user( 'Admin', 'admin' );

    # Add "Admin" user with the new password
    $self->add_user( 'Admin', $new_admins_password, 'admin' );

    # delete temp admin user
    $self->delete_user( 'tempadmin', 'admin' );
}
# }}}
# Edit Program Alarm Templates
# {{{ pat_mdi_mlr_edit
sub pat_mdi_mlr_edit {

    my $self = shift;

    my $template = $_[0];
    my $mdi_mlr_value = $_[1];

    #my $url_string = '/prot/videoprogramfault.html?programFault_list=0&programFault_submit=Add%2FUpdate&programFault_template='.$template.'&progF_mlr='.$mdi_mlr_value;

    #$self->{mech}->get( "http://".$self->{PAGE_IP}.$url_string );

    $self->run_alarm_template_checkbox_and_val( 'program', 'progF_mlr', 'none', $_[0], $_[1], '-1' );
}
# }}}
# {{{ pat_pmla_mlt15
sub pat_pmla_mlt15 {

    my $self = shift;

    my $template = $_[0];
    my $enable_disable = $_[1];
    my $new_val = $_[2];

    my $url_string = '/prot/videoprogramfault.html?programFault_list=0&programFault_submit=Add%2FUpdate&programFault_template='.$template.'&bpfMLoss15='.$enable_disable.'&progF_ccloss='.$new_val;

    $self->{mech}->get( "http://".$self->{PAGE_IP}.$url_string );
}
# }}}
# {{{ pat_pmla_mls_lp
sub pat_pmla_mls_lp {

    my $self = shift;

    my $template = $_[0];
    my $enable_disable = $_[1];
    my $new_val = $_[2];

    my $url_string = '/prot/videoprogramfault.html?programFault_list=0&programFault_submit=Add%2FUpdate&programFault_template='.$template.'&bpfMLp='.$enable_disable.'&progF_Lp='.$new_val;

    $self->{mech}->get( "http://".$self->{PAGE_IP}.$url_string );
}
# }}}
# {{{ pat_pmla_mlt24
sub pat_pmla_mlt24 {

    my $self = shift;

    my $template = $_[0];
    my $enable_disable = $_[1];
    my $new_val = $_[2];

    my $url_string = '/prot/videoprogramfault.html?programFault_list=0&programFault_submit=Add%2FUpdate&programFault_template='.$template.'&bpfMLoss='.$enable_disable.'&progF_loss24='.$new_val;

    $self->{mech}->get( "http://".$self->{PAGE_IP}.$url_string );
}
# }}}
# {{{ pat_pmla_mls_ld
sub pat_pmla_mls_ld {

    my $self = shift;

    my $template = $_[0];
    my $enable_disable = $_[1];
    my $new_val = $_[2];

    my $url_string = '/prot/videoprogramfault.html?programFault_list=0&programFault_submit=Add%2FUpdate&programFault_template='.$template.'&bpfMLd='.$enable_disable.'&progF_Ld='.$new_val;

    $self->{mech}->get( "http://".$self->{PAGE_IP}.$url_string );
}
# }}}
# {{{ pat_pmla_mls24
sub pat_pmla_mls24 {

    my $self = shift;

    my $template = $_[0];
    my $enable_disable = $_[1];
    my $new_val = $_[2];

    my $url_string = '/prot/videoprogramfault.html?programFault_list=0&programFault_submit=Add%2FUpdate&programFault_template='.$template.'&bpfMls24='.$enable_disable.'&progF_mls24='.$new_val;

    $self->{mech}->get( "http://".$self->{PAGE_IP}.$url_string );
}
# }}}
# {{{ pat_pmla_mls15
sub pat_pmla_mls15 {

    my $self = shift;

    my $template = $_[0];
    my $enable_disable = $_[1];
    my $new_val = $_[2];

    my $url_string = '/prot/videoprogramfault.html?programFault_list=0&programFault_submit=Add%2FUpdate&programFault_template='.$template.'&bpfMls15='.$enable_disable.'&progF_mls15='.$new_val;

    $self->{mech}->get( "http://".$self->{PAGE_IP}.$url_string );
}
# }}}
# {{{ edit_pat_pma_program_scramble_state
sub edit_pat_pma_program_scramble_state {

    my $self = shift;

    my $template = $_[0];
    my $enable_disable = $_[1];
    my $new_val = $_[2];

    my $url_string = '/prot/videoprogramfault.html?programFault_list=0&programFault_submit=Add%2FUpdate&programFault_template='.$template.'&progF_bscramble='.$enable_disable.'&progF_scramble='.$new_val;

    $self->{mech}->get( "http://".$self->{PAGE_IP}.$url_string );
}
# }}}
# {{{ edit_pat_pma_pid_monitor_status
sub edit_pat_pma_pid_monitor_status {

    my $self = shift;

    my $template = $_[0];
    my $new_val = $_[1];

    my $url_string = '/prot/videoprogramfault.html?programFault_list=0&programFault_submit=Add%2FUpdate&programFault_template='.$template.'&progF_control='.$new_val;

    $self->{mech}->get( "http://".$self->{PAGE_IP}.$url_string );
}
# }}}
# {{{ edit_pat_pma_pid_alarm_trigger_period
sub edit_pat_pma_pid_alarm_trigger_period {

    my $self = shift;

    my $template = $_[0];
    my $new_val = $_[1]; 
    
    my $url_string = '/prot/videoprogramfault.html?programFault_list=0&programFault_submit=Add%2FUpdate&programFault_template='.$template.'&progF_soak='.$new_val;
    
    $self->{mech}->get( "http://".$self->{PAGE_IP}.$url_string );
}
# }}}
# {{{ edit_pat_pma_ignore_secondary_audio_pid
sub edit_pat_pma_ignore_secondary_audio_pid {

    my $self = shift;

    my $template = $_[0];
    my $new_val = $_[1];

    my $url_string = '/prot/videoprogramfault.html?programFault_list=0&programFault_submit=Add%2FUpdate&programFault_template='.$template.'&progF_iAudio='.$new_val;
    
    $self->{mech}->get( "http://".$self->{PAGE_IP}.$url_string );
}
# }}}
# {{{ edit_pat_pma_scte35_detection
sub edit_pat_pma_scte35_detection {

    my $self = shift;

    my $template = $_[0];
    my $new_val = $_[1];

    my $url_string = '/prot/videoprogramfault.html?programFault_list=0&programFault_submit=Add%2FUpdate&programFault_template='.$template.'&progF_bScte='.$new_val;

    $self->{mech}->get( "http://".$self->{PAGE_IP}.$url_string );
}
# }}}
# {{{ edit_pat_pma_max_inactivity_period_scte35 
sub edit_pat_pma_max_inactivity_period_scte35 {

    my $self = shift;

    my $template = $_[0];
    my $enable_disable = $_[1];
    my $new_val = $_[2];

    my $url_string = '/prot/videoprogramfault.html?programFault_list=0&programFault_submit=Add%2FUpdate&programFault_template='.$template.'&progF_bScteIvl='.$enable_disable.'&progF_ScteIvl='.$new_val;

    $self->{mech}->get( "http://".$self->{PAGE_IP}.$url_string );
}
# }}}
# {{{ edit_ppbma_video_outage_val
sub edit_ppbma_video_outage_val {

    my $self = shift;

    my $template = $_[0];
    my $enable_disable = $_[1];
    my $new_val = $_[2];

    my $url_string = '/prot/videoprogramfault.html?programFault_list=0&programFault_submit=Add%2FUpdate&programFault_template='.$template.'&progF_Ovideo='.$enable_disable.'&progF_ovidpid='.$new_val;

    $self->{mech}->get( "http://".$self->{PAGE_IP}.$url_string );
}
# }}}
# {{{ edit_ppbma_video_min_val
sub edit_ppbma_video_min_val {

    my $self = shift;

    my $template = $_[0];
    my $enable_disable = $_[1];
    my $new_val = $_[2];

    my $url_string = '/prot/videoprogramfault.html?programFault_list=0&programFault_submit=Add%2FUpdate&programFault_template='.$template.'&progF_video='.$enable_disable.'&progF_vidpid='.$new_val;

    $self->{mech}->get( "http://".$self->{PAGE_IP}.$url_string );
}
# }}}
# {{{ edit_ppbma_video_max_val 
sub edit_ppbma_video_max_val {

    my $self = shift;

    my $template = $_[0];
    my $enable_disable = $_[1];
    my $new_val = $_[2];

    my $url_string = '/prot/videoprogramfault.html?programFault_list=0&programFault_submit=Add%2FUpdate&programFault_template='.$template.'&progF_mvideo='.$enable_disable.'&progF_mvidpid='.$new_val;

    $self->{mech}->get( "http://".$self->{PAGE_IP}.$url_string );
}
# }}}
# {{{ edit_ppbma_audo_outage_val
sub edit_ppbma_audo_outage_val {

    my $self = shift;

    my $template = $_[0];
    my $enable_disable = $_[1];
    my $new_val = $_[2];

    my $url_string = '/prot/videoprogramfault.html?programFault_list=0&programFault_submit=Add%2FUpdate&programFault_template='.$template.'&progF_OAudio='.$enable_disable.'&progF_oaudpid='.$new_val;

    $self->{mech}->get( "http://".$self->{PAGE_IP}.$url_string );
}
# }}}
# {{{ edit_ppbma_audio_min_val
sub edit_ppbma_audio_min_val {

    my $self = shift;

    my $template = $_[0];
    my $enable_disable = $_[1];
    my $new_val = $_[2];

    my $url_string = '/prot/videoprogramfault.html?programFault_list=0&programFault_submit=Add%2FUpdate&programFault_template='.$template.'&progF_audio='.$enable_disable.'&progF_audpid='.$new_val;

    $self->{mech}->get( "http://".$self->{PAGE_IP}.$url_string );
}
# }}}
# {{{ edit_ppbma_audio_max_val
sub edit_ppbma_audio_max_val {

    my $self = shift;

    my $template = $_[0];
    my $enable_disable = $_[1];
    my $new_val = $_[2];

    my $url_string = '/prot/videoprogramfault.html?programFault_list=0&programFault_submit=Add%2FUpdate&programFault_template='.$template.'&progF_maudio='.$enable_disable.'&progF_maudpid='.$new_val;

    $self->{mech}->get( "http://".$self->{PAGE_IP}.$url_string );
}
# }}}
# {{{ edit_ppbma_pmt_pid_outage
sub edit_ppbma_pmt_pid_outage {

    my $self = shift;
    
    my $template = $_[0];
    my $new_val = $_[1];
    
    my $url_string = '/prot/videoprogramfault.html?programFault_list=0&programFault_submit=Add%2FUpdate&programFault_template='.$template.'&progF_pmt='.$new_val;
    
    $self->{mech}->get( "http://".$self->{PAGE_IP}.$url_string );
}
# }}}
# {{{ edit_ppbma_pmt_pcr_pid_outage
sub edit_ppbma_pmt_pcr_pid_outage {

    my $self = shift;
 
    my $template = $_[0];
    my $new_val = $_[1];

    my $url_string = '/prot/videoprogramfault.html?programFault_list=0&programFault_submit=Add%2FUpdate&programFault_template='.$template.'&progF_pcr='.$new_val;

    $self->{mech}->get( "http://".$self->{PAGE_IP}.$url_string );
}
# }}}
# Transport Flow Alarms Settings - IP/RTP Loss Alarms
# {{{ edit_tat_flow_ip_rtp_loss_alarms_program_loss_alarm_count
sub edit_tat_flow_ip_rtp_loss_alarms_program_loss_alarm_count {

    my $self = shift;

    $self->run_alarm_template_checkbox_and_val( 'transport', 'sF_bProgCount', 'sF_progCount', $_[0], $_[1], $_[2] );
}
# }}}
# {{{ edit_tat_flow_ip_rtp_loss_alarms_ts_algn
sub edit_tat_flow_ip_rtp_loss_alarms_ts_algn {

    my $self = shift;

    $self->run_alarm_template_checkbox_and_val( 'transport', 'videoTs_bAlign', 'none', $_[0], $_[1], '-1' );
}
# }}}
# {{{ edit_tat_flow_ip_rtp_loss_alarms_rtp_lp
sub edit_tat_flow_ip_rtp_loss_alarms_rtp_lp {

    my $self = shift;

    $self->run_alarm_template_checkbox_and_val( 'transport', 'bsfRtplp', 'sF_rtplp', $_[0], $_[1], $_[2] );
}
# }}}
# {{{ edit_tat_flow_ip_rtp_loss_alarms_rtp_ld
sub edit_tat_flow_ip_rtp_loss_alarms_rtp_ld {

    my $self = shift;

    $self->run_alarm_template_checkbox_and_val( 'transport', 'bsfRtpld', 'sF_rtpld', $_[0], $_[1], $_[2] );
}
# }}}
# {{{ edit_tat_flow_ip_rtp_loss_alarms_rtp_se15
sub edit_tat_flow_ip_rtp_loss_alarms_rtp_se15 {

    my $self = shift;

    $self->run_alarm_template_checkbox_and_val( 'transport', 'bsfRtptotloss', 'sF_rtptotloss', $_[0], $_[1], $_[2] );
}
# }}}
# {{{ edit_tat_flow_ip_rtp_loss_alarms_rtp_se24
sub edit_tat_flow_ip_rtp_loss_alarms_rtp_se24 {

    my $self = shift;

    $self->run_alarm_template_checkbox_and_val( 'transport', 'bsfRtploss24', 'sF_rtploss24', $_[0], $_[1], $_[2] );
}
#}}}
# {{{ edit_tat_flow_ip_rtp_loss_alarms_rtp_ls15
sub edit_tat_flow_ip_rtp_loss_alarms_rtp_ls15 {

    my $self = shift;

    $self->run_alarm_template_checkbox_and_val( 'transport', 'bsfls15', 'sF_ls15', $_[0], $_[1], $_[2] );
}
# }}}
# {{{ edit_tat_flow_ip_rtp_loss_alarms_rtp_ls24
sub edit_tat_flow_ip_rtp_loss_alarms_rtp_ls24 {

    my $self = shift;

    $self->run_alarm_template_checkbox_and_val( 'transport', 'bsfls24', 'sF_ls24', $_[0], $_[1], $_[2] );
}
# }}}
# {{{ edit_tat_flow_ip_rtp_loss_alarms_rtp_dup
sub edit_tat_flow_ip_rtp_loss_alarms_rtp_dup {

    my $self = shift;
    $self->run_alarm_template_checkbox_and_val( 'transport', 'sF_rtpDup', 'none', $_[0], $_[1], '-1' );
}
# }}}
# {{{ edit_tat_flow_ip_rtp_loss_alarms_rtp_oos
sub edit_tat_flow_ip_rtp_loss_alarms_rtp_oos {

    my $self = shift;
    $self->run_alarm_template_checkbox_and_val( 'transport', 'sF_rtpOos', 'none', $_[0], $_[1], '-1' );
}
# }}}
# Transport Flow Alarms Settings - Packet Arrival Time
# {{{ edit_tat_flow_pat_mdi_df
sub edit_tat_flow_pat_mdi_df {

    my $self = shift;

    $self->run_alarm_template_checkbox_and_val( 'transport', 'bsfMdi', 'sF_mdi', $_[0], $_[1], $_[2] );
}
# }}}
# {{{ edit_tat_flow_pat_mdi_vbuf
sub edit_tat_flow_pat_mdi_vbuf {

    my $self = shift;

    $self->run_alarm_template_checkbox_and_val( 'transport', 'bsfVb', 'sF_VB', $_[0], $_[1], $_[2] );
}
# }}}
# {{{ edit_tat_flow_pat_igmp_lve
sub edit_tat_flow_pat_igmp_lve {

    my $self = shift;

    $self->run_alarm_template_checkbox_and_val( 'transport', 'bsfLve', 'sF_lve', $_[0], $_[1], $_[2] );
}
# }}}
# {{{ edit_tat_flow_pat_igmp_zap
sub edit_tat_flow_pat_igmp_zap {

    my $self = shift;

    $self->run_alarm_template_checkbox_and_val( 'transport', 'bsfZap', 'sF_zap', $_[0], $_[1], $_[2] );
}
# }}}
# {{{ edit_tat_flow_pat_ip_sbr_radio_button
sub edit_tat_flow_pat_ip_sbr_radio_button {

    my $self = shift;

    $self->run_alarm_template_checkbox_and_val( 'transport', 'bsfMaxBit', 'none', $_[0], $_[1], '-1' );
}
# }}}
# {{{ edit_tat_flow_pat_ip_sbr_deviation_percent_value
sub edit_tat_flow_pat_ip_sbr_deviation_percent_value {

    my $self = shift;

    $self->run_alarm_template_checkbox_and_val( 'transport', 'sF_bitDev', 'none', $_[0], $_[1], '-1' );
}
# }}}
# {{{ edit_tat_flow_pat_ip_sbr_ip_sbrmx
sub edit_tat_flow_pat_ip_sbr_ip_sbrmx {

    my $self = shift;

    $self->run_alarm_template_checkbox_and_val( 'transport', 'bsfmaxbps', 'sF_maxbps', $_[0], $_[1], $_[2] );
}
# }}}
# {{{ edit_tat_flow_pat_ip_sbr_ip_sbrmn
sub edit_tat_flow_pat_ip_sbr_ip_sbrmn {

    my $self = shift;

    $self->run_alarm_template_checkbox_and_val( 'transport', 'bsfminbps', 'sF_minbps', $_[0], $_[1], $_[2] );
}
# }}}
# {{{ edit_tat_flow_pat_vido_los
sub edit_tat_flow_pat_vido_los {
    
    my $self = shift;

    $self->run_alarm_template_checkbox_and_val( 'transport', 'sF_out', 'none', $_[0], $_[1], '-1' );
}
# }}}
# Transport - Transport Stream - General
# {{{ edit_tat_ts_general_ts_video_servise_name_detection
sub edit_tat_ts_general_ts_video_servise_name_detection {

    my $self = shift;

    $self->run_alarm_template_checkbox_and_val( 'transport', 'videoTs_svcname', 'none', $_[0], $_[1], '-1' );
}
# }}}
# {{{ edit_tat_ts_general_stream_end_timeout
sub edit_tat_ts_general_stream_end_timeout {

    my $self = shift;

    $self->run_alarm_template_checkbox_and_val( 'transport', 'videoTs_timeout', 'none', $_[0], $_[1], '-1' );
}
# }}}
# {{{ edit_tat_ts_general_video_source
sub edit_tat_ts_general_video_source {

    my $self = shift;

    $self->run_alarm_template_checkbox_and_val( 'transport', 'videoTs_encoder', 'none', $_[0], $_[1], '-1' );
}
# }}}
# {{{ edit_tat_ts_general_bit_rate_type
sub edit_tat_ts_general_bit_rate_type {

    my $self = shift;

    $self->run_alarm_template_checkbox_and_val( 'transport', 'videoTs_bittype', 'none', $_[0], $_[1], '-1' );
}
# }}}
# {{{ edit_tat_ts_general_stream_bit_rate
sub edit_tat_ts_general_stream_bit_rate {

    my $self = shift;

    $self->run_alarm_template_checkbox_and_val( 'transport', 'videoTs_bitstatus', 'videoTs_bitrate', $_[0], $_[1], $_[2] );
}
# }}}
# {{{ edit_tat_ts_general_v_tsb
sub edit_tat_ts_general_v_tsb {

    my $self = shift;

    $self->run_alarm_template_checkbox_and_val( 'transport', 'videoTs_bPcrBit', 'videoTs_pcrbit', $_[0], $_[1], $_[2] ); 
}
# }}}
# {{{ edit_tat_ts_general_unref_pid
sub edit_tat_ts_general_unref_pid {

    my $self = shift;

    $self->run_alarm_template_checkbox_and_val( 'transport', 'videoTs_bUnref', 'none', $_[0], $_[1], '-1' );
}
# }}}
# {{{ edit_tat_ts_general_ts_snc
sub edit_tat_ts_general_ts_snc {

    my $self = shift;

    $self->run_alarm_template_checkbox_and_val( 'transport', 'videoTs_bSync', 'none', $_[0], $_[1], '-1' );
}
# }}}
# {{{ edit_tat_ts_general_program_changes_traps
sub edit_tat_ts_general_program_changes_traps {

    my $self = shift;

    $self->run_alarm_template_checkbox_and_val( 'transport', 'videoTs_ProgChg', 'none', $_[0], $_[1], '-1' );
}
# }}}
# {{{ edit_tat_ts_general_pat_pid_outage
sub edit_tat_ts_general_pat_pid_outage {

    my $self = shift;

    $self->run_alarm_template_checkbox_and_val( 'transport', 'videoTs_pat', 'none', $_[0], $_[1], '-1' );
}
# }}}
# Transport - Transort Stream - Non Program PID Monitoring
# {{{ edit_tat_ts_nppm_monitoring_level
sub edit_tat_ts_nppm_monitoring_level {

    my $self = shift;

    $self->run_alarm_template_checkbox_and_val( 'transport', 'videoTs_iAll', 'none', $_[0], $_[1], '-1' );
}
# }}}
# {{{ edit_tat_ts_nppm_mdi_mlr
sub edit_tat_ts_nppm_mdi_mlr {

    my $self = shift;

    $self->run_alarm_template_checkbox_and_val( 'transport', 'sF_mlr', 'none', $_[0], $_[1], '-1' );
}
# }}}
# {{{ edit_tat_ts_nppm_mls_lp
sub edit_tat_ts_nppm_mls_lp {

    my $self = shift;

    $self->run_alarm_template_checkbox_and_val( 'transport', 'bsfMLp', 'sF_mlp', $_[0], $_[1], $_[2] );
}
# }}}
# {{{ edit_tat_ts_nppm_mls_ld
sub edit_tat_ts_nppm_mls_ld {

    my $self = shift;

    $self->run_alarm_template_checkbox_and_val( 'transport', 'bsfMLd', 'sF_mld', $_[0], $_[1], $_[2] );
}
# }}}
# {{{ edit_tat_ts_nppm_mlt_15
sub edit_tat_ts_nppm_mlt_15 {

    my $self = shift;

    $self->run_alarm_template_checkbox_and_val( 'transport', 'bsfMl15', 'sF_ccloss', $_[0], $_[1], $_[2] );
}
# }}}
# {{{ edit_tat_ts_nppm_mlt_24
sub edit_tat_ts_nppm_mlt_24 {

    my $self = shift;

    $self->run_alarm_template_checkbox_and_val( 'transport', 'bsfMl24', 'sF_mloss24', $_[0], $_[1], $_[2] );
}
# }}}
# {{{ edit_tat_ts_nppm_mls_15
sub edit_tat_ts_nppm_mls_15 {

    my $self = shift;

    $self->run_alarm_template_checkbox_and_val( 'transport', 'bsfMls15', 'sF_mls15', $_[0], $_[1], $_[2] );
}
# }}}
# {{{ edit_tat_ts_nppm_mls_24
sub edit_tat_ts_nppm_mls_24 {

    my $self = shift;

    $self->run_alarm_template_checkbox_and_val( 'transport', 'bsfMls24', 'sF_mls24', $_[0], $_[1], $_[2] );
}
# }}}
# Transport - Transport Stream - Stuffing PID Threshold
# {{{ edit_tat_ts_spt_min
sub edit_tat_ts_spt_min {

    my $self = shift;

    $self->run_alarm_template_checkbox_and_val( 'transport', 'videoTs_stuff', 'videoTs_stuffpid', $_[0], $_[1], $_[2] );
}
# }}}
# {{{ edit_tat_ts_spt_max
sub edit_tat_ts_spt_max {

    my $self = shift;

    $self->run_alarm_template_checkbox_and_val( 'transport', 'videoTs_mstuff', 'videoTs_mstuffpid', $_[0], $_[1], $_[2] );
}
# }}}
# Transport - Transport Stream - Mask Errors During FF/Rewind
# {{{ edit_tat_ts_medffr_checkbox
sub edit_tat_ts_medffr_checkbox {

    my $self = shift;

    $self->run_alarm_template_checkbox_and_val( 'transport', 'videoTs_bffrew', 'none', $_[0], $_[1], '-1' ); 
}
# }}}
#{{{ edit_tat_ts_medffr_radio_and_value
sub edit_tat_ts_medffr_radio_and_value {

    my $self = shift;

    $self->run_alarm_template_checkbox_and_val( 'transport', 'videoTs_fftype', 'videoTs_ffrew', $_[0], $_[1], $_[2] );
}
## }}}
# Transport - Transport Stream - Transport Stream User PIDs
# {{{ edit_tat_ts_tsup_user_pid_1 
sub edit_tat_ts_tsup_user_pid_1 {

    my $self = shift;

    $self->run_alarm_template_checkbox_and_val( 'transport', 'videoTs_pidtype1Act', 'videoTs_pid1Text', $_[0], $_[1], $_[2] );
}
# }}}
# Transport - Transport Stream - ETSI TR 101 290 First Priority
# {{{ edit_tat_etsi_fp_ts_sync_loss
sub edit_tat_etsi_fp_ts_sync_loss {

    my $self = shift;

    $self->run_alarm_template_checkbox_and_val( 'transport', 'etr11', 'none', $_[0], $_[1], '-1' );
}
# }}}
# {{{ edit_tat_etsi_fp_sync_byte_error
sub edit_tat_etsi_fp_sync_byte_error {

    my $self = shift;

    $self->run_alarm_template_checkbox_and_val( 'transport', 'etr12', 'none', $_[0], $_[1], '-1' );
}
# }}}
# {{{ edit_tat_etsi_fp_pat_error
sub edit_tat_etsi_fp_pat_error {

    my $self = shift;

    $self->run_alarm_template_checkbox_and_val( 'transport', 'etr13', 'letr13', $_[0], $_[1], $_[2] );
}
# }}}
# {{{ edit_tat_etsi_fp_continuity_count_error
sub edit_tat_etsi_fp_continuity_count_error {

    my $self = shift;

    $self->run_alarm_template_checkbox_and_val( 'transport', 'etr14', 'none', $_[0], $_[1], '-1' );
}
# }}}
# {{{ edit_tat_etsi_fp_pmt_error
sub edit_tat_etsi_fp_pmt_error {

    my $self = shift;

    $self->run_alarm_template_checkbox_and_val( 'transport', 'etr15', 'letr15', $_[0], $_[1], $_[2] );
}
# }}}
# {{{ edit_tat_etsi_fp_pid_error_1
sub edit_tat_etsi_fp_pid_error_1 {

    my $self = shift;

    $self->run_alarm_template_checkbox_and_val( 'transport', 'etr16a', 'petr16a', $_[0], $_[1], $_[2] );
}
sub edit_tat_etsi_fp_pid_error_1_slider {

    my $self = shift;

    $self->run_alarm_template_checkbox_and_val( 'transport', 'letr16a', 'none', $_[0], $_[1], '-1' );
}
# }}}
# {{{ edit_tat_etsi_fp_pid_error_2
sub edit_tat_etsi_fp_pid_error_2 {

    my $self = shift;

    $self->run_alarm_template_checkbox_and_val( 'transport', 'etr16b', 'petr16b', $_[0], $_[1], $_[2] );
}
sub edit_tat_etsi_fp_pid_error_2_slider {

    my $self = shift;

    $self->run_alarm_template_checkbox_and_val( 'transport', 'letr16b', 'none', $_[0], $_[1], '-1' );
}
# }}}
# {{{ edit_tat_etsi_fp_pid_error_3
sub edit_tat_etsi_fp_pid_error_3 {

    my $self = shift;

    $self->run_alarm_template_checkbox_and_val( 'transport', 'etr16c', 'petr16c', $_[0], $_[1], $_[2] );
}
sub edit_tat_etsi_fp_pid_error_3_slider {

    my $self = shift;

    $self->run_alarm_template_checkbox_and_val( 'transport', 'letr16c', 'none', $_[0], $_[1], '-1' );
}
# }}}
# {{{ edit_tat_etsi_fp_pid_error_4
sub edit_tat_etsi_fp_pid_error_4 {

    my $self = shift;

    $self->run_alarm_template_checkbox_and_val( 'transport', 'etr16d', 'petr16d', $_[0], $_[1], $_[2] );
}
sub edit_tat_etsi_fp_pid_error_4_slider {

    my $self = shift;

    $self->run_alarm_template_checkbox_and_val( 'transport', 'letr16d', 'none', $_[0], $_[1], '-1' );
}
# }}}
# Transport - Transport Stream - ETSI 101 290 Second Priority
# {{{ edit_tat_etsi_sp_transport_error
sub edit_tat_etsi_sp_transport_error {

    my $self = shift;

    $self->run_alarm_template_checkbox_and_val( 'transport', 'etr21', 'none', $_[0], $_[1], '-1' );
}
# }}}
# {{{ edit_tat_etsi_sp_crc_error
sub edit_tat_etsi_sp_crc_error {

    my $self = shift;

    $self->run_alarm_template_checkbox_and_val( 'transport', 'etr22', 'none', $_[0], $_[1], '-1' );
}
# }}}
# {{{ edit_tat_etsi_sp_pcr_repetition_error
sub edit_tat_etsi_sp_pcr_repetition_error {

    my $self = shift;
    
    $self->run_alarm_template_checkbox_and_val( 'transport', 'etr23', 'letr23a', $_[0], $_[1], $_[2] );
}
# }}}
# {{{ edit_tat_etsi_sp_pcr_discontinuity_error
sub edit_tat_etsi_sp_pcr_discontinuity_error {

    my $self = shift;
    
    $self->run_alarm_template_checkbox_and_val( 'transport', 'letr23b', 'none', $_[0], $_[1], '-1' );
}
# }}}
# {{{ edit_tat_etsi_sp_pcr_accuracy_error
sub edit_tat_etsi_sp_pcr_accuracy_error {

    my $self = shift;
    
    $self->run_alarm_template_checkbox_and_val( 'transport', 'etr24', 'letr24', $_[0], $_[1], $_[2] );
}
# }}}
# {{{ edit_tat_etsi_sp_pts_repetition_error
sub edit_tat_etsi_sp_pts_repetition_error {

    my $self = shift;

    $self->run_alarm_template_checkbox_and_val( 'transport', 'etr25', 'letr25', $_[0], $_[1], $_[2] );
}
# }}}
# {{{ edit_tat_etsi_sp_cat_error
sub edit_tat_etsi_sp_cat_error {

    my $self = shift;
 
    $self->run_alarm_template_checkbox_and_val( 'transport', 'etr26', 'none', $_[0], $_[1], '-1' );
}
# }}}
## Internal Functions
# {{{ run_alarm_template_checkbox_and_val
sub run_alarm_template_checkbox_and_val {
# This function runs the get string for changing the alarm templates.  It specifically changes the ones with the checkbox and some numerical value ones. 

    my $self = shift;

    my $type = $_[0];  # transport or program
    my $checkbox_name = $_[1];
    my $inputfield_name = $_[2];
    my $template = $_[3];
    my $enable_disable = $_[4];
    my $new_val = $_[5];

    my $url_string = '';

    if( $type =~ /transport/ ){

        $url_string = '/prot/videoalarm.html?videoTs_list=0&videochar_submit=Add%2FUpdate&videoTs_name='.$template.'&'.$checkbox_name.'='.$enable_disable.'&'.$inputfield_name.'='.$new_val;
    }
    if( $type =~ /program/ ){

        $url_string = '/prot/videoprogramfault.html?programFault_list=0&programFault_submit=Add%2FUpdate&programFault_template='.$template.'&'.$checkbox_name.'='.$enable_disable.'&'.$inputfield_name.'='.$new_val;
    }

    $self->{mech}->get( "http://".$self->{PAGE_IP}.$url_string );
}
# }}}
1;

