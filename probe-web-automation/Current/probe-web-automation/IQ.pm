#!/usr/bin/perl
# vim: set expandtab tabstop=4 shiftwidth=4 softtabstop=4 foldmethod=marker: #

#
# A Class to interact with Ineoquest Probes
#
# Probe Types:
# Media Monitor: mm
# G1T: g1t
# G2X: g2x
# Cricket FG: c-fg
# Cricket QAM: qam
# Cricket IP: c-ip
# Cricket ASI: c-asi
#

package IQ;
use strict;
use WWW::Mechanize;
use HTTP::Cookies;
#use XML::Parser;
#use XML::SimpleObject;
use Switch;
use LWP 5.64;
use Digest::MD5;

# Probe Connection Functions
# {{{ new
sub new {
        my $self  = {};

	$self->{PAGE_IP} = undef;
    $self->{mech} = undef;
    $self->{probe_type} = undef;

        bless($self);
        return $self;
}
# }}}
# {{{ start_mech
sub start_mech {

    my $self = shift;

    my $mech = WWW::Mechanize->new( autocheck => 1 );

    #$mech->agent => "Mozilla/4.0 (compatible; MSIE 6.0; Windows NT 5.1)";

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
# {{{ set_probe_type
sub set_probe_type {

    my $self = shift;

    $self->{probe_type} = $_[0];
}
# }}}
# {{{ login
sub login {

	my $self = shift;

    my $returnCode = 1;

    my $username = $_[0];
    my $password = $_[1];

    eval{

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
                'argList' => 'REMOTE_ADDR=172.25.157.210 SERVER_SOFTWARE=INEOQUEST/2.0 SERVER_NAME=IQ Cricket SERVER_PROTOCOL=HTTP/1.1 SERVER_PORT=80 REQUEST_METHOD=GET PATH_INFO=/ HOST= '.$self->{PAGE_IP}.' ACCEPT_ENCODING=gzip,deflate END_OF_HEADERS=',
                'encoded' => $username . ':' . $encoded_string,
                'mimeHeaderList' => 'Content-Encoding=gzip',
                                'nonce' => $nounce
                            ],
                        );
    };
    if ($@){
        $returnCode = -1;
    }

    return $returnCode;
}
# }}}
# {{{ Logout
sub logout {

    my $self = shift;

    $self->{mech}->get("http://".$self->{PAGE_IP}."/dynamic/logout.htm");

    return 1;
}
# }}}
# Probe Functions
# {{{ get_url_and_return_content
sub get_url_and_return_content {

	my $self = shift;

	my $users_url = $_[0];

	$self->{mech}->get("http://".$self->{PAGE_IP}.$users_url);

	return $self->{mech}->content();
}
# }}}
# User Manip Functions
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
# System Configuration
# {{{ systemconfiguration_edit_get_community_string
sub systemconfiguration_edit_get_community_string {

    my $self = shift;

    my $val = $_[0];

    $self->{mech}->get("http://".$self->{PAGE_IP}."/config/snmpconfig.html?snmpconfig=Update+Config&snmp_getcommunity=".$val);

}
# }}}
# {{{ systemconfiguration_edit_set_community_string
sub systemconfiguration_edit_set_community_string {

    my $self = shift;
    my $val = $_[0];

    $self->{mech}->get("http://".$self->{PAGE_IP}."/config/snmpconfig.html?snmpconfig=Update+Config&snmp_setcommunity=".$val);

}
# }}}
# {{{ systemconfiguration_edit_set_primary_trap_destination
sub systemconfiguration_edit_set_primary_trap_destination {

    my $self = shift;
    my $val = $_[0];

    $self->{mech}->get("http://".$self->{PAGE_IP}."/config/snmpconfig.html?snmp_trapip1=".$val);

}
# }}}
# {{{ systemconfiguration_set_xPRT_and_start_performance_test
sub systemconfiguration_set_xPRT_and_start_performance_test {

    my $self = shift;
    my $val = $_[0];

    $self->{mech}->get("http://".$self->{PAGE_IP}."/prot/vcpt.html?vc_pt_enable=0&vc_pt_disable=0&vc_pt_start=Start&vc_pt_stop=0&vc_pt_apply=0&vc_pt_ip_addr=".$val."&vc_pt_so_timeout=10" );

}
# }}}

# Configuration Management
# {{{ configurationmanagement_saveconfiguration_saveandreset
sub configurationmanagement_saveconfiguration_saveandreset{

    my $self = shift;

    $self->{mech}->get("http://".$self->{PAGE_IP}."/reset.html?downloadconfig=Apply&server_ipaddress=1" );

}
# }}}

# Edit Program Alarm Templates
# {{{ program_alarm_template_add
sub program_alarm_template_add{

    my $self = shift;

    my $programFault_list = $_[0];
    my $programFault_submit = $_[1];
    my $programFault_template = $_[2];
    my $progF_mlr = $_[3];
    my $bpfMLp = $_[4];
    my $progF_Lp = $_[5];
    my $bpfMLd = $_[6];
    my $progF_Ld = $_[7];
    my $bpfMLoss15 = $_[8];
    my $progF_ccloss = $_[9];
    my $bpfMLoss = $_[10];
    my $progF_loss24 = $_[11];
    my $bpfMls24 = $_[12];
    my $progF_mls24 = $_[13];
    my $bpfMls15 = $_[14];
    my $progF_mls15 = $_[15];
    my $progF_control = $_[16];
    my $progF_bscramble = $_[17];
    my $progF_scramble = $_[18];
    my $progF_outsoak = $_[19];
    my $progF_soak = $_[20];
    my $progF_iAudio = $_[21];
    my $progF_pidtype1 = $_[22];
    my $progF_pid1 = $_[23];
    my $progF_pidtype2 = $_[24];
    my $progF_pid2 = $_[25];
    my $progF_pidtype3 = $_[26];
    my $progF_pid3 = $_[27];
    my $progF_pidtype1Act = $_[28];
    my $progF_pid1Text = $_[29];
    my $progF_pid1Sel = $_[30];
    my $progF_bPid1 = $_[31];
    my $progF_thr1 = $_[32];
    my $progF_bmPid1 = $_[33];
    my $progF_mthr1 = $_[34];
    my $progF_pidtype2Act = $_[35];
    my $progF_pid2Text = $_[36];
    my $progF_pid2Sel = $_[37];
    my $progF_bPid2 = $_[38];
    my $progF_thr2 = $_[39];
    my $progF_bmPid2 = $_[40];
    my $progF_mthr2 = $_[41];
    my $progF_pidtype3Act = $_[42];
    my $progF_pid3Text = $_[43];
    my $progF_pid3Sel = $_[44];
    my $progF_bPid3 = $_[45];
    my $progF_thr3 = $_[46];
    my $progF_bmPid3 = $_[47];
    my $progF_mthr3 = $_[48];
    my $progF_Ovideo = $_[49];
    my $progF_ovidpid = $_[50];
    my $progF_video = $_[51];
    my $progF_vidpid = $_[52];
    my $progF_mvideo = $_[53];
    my $progF_mvidpid = $_[54];
    my $progF_OAudio = $_[55];
    my $progF_oaudpid = $_[56];
    my $progF_audio = $_[57];
    my $progF_audpid = $_[58];
    my $progF_maudio = $_[59];
    my $progF_maudpid = $_[60];
    my $progF_pmt = $_[61];
    my $progF_pcr = $_[62];

    my $url_string = '/prot/videoprogramfault.html?programFault_list='.$programFault_list.'&programFault_submit=Add%2FUpdate&programFault_template='.$programFault_template.'&progF_mlr='.$progF_mlr.'&bpfMLp='.$bpfMLp.'&progF_Lp='.$progF_Lp.'&bpfMLd='.$bpfMLd.'&progF_Ld='.$progF_Ld.'&bpfMLoss15='.$bpfMLoss15.'&progF_ccloss='.$progF_ccloss.'&bpfMLoss='.$bpfMLoss.'&progF_loss24='.$progF_loss24.'&bpfMls24='.$bpfMls24.'&progF_mls24='.$progF_mls24.'&bpfMls15='.$bpfMls15.'&progF_mls15='.$progF_mls15.'&progF_control='.$progF_control.'&progF_bscramble='.$progF_bscramble.'.&progF_scramble='.$progF_scramble.'&progF_outsoak='.$progF_outsoak.'&progF_soak='.$progF_soak.'&progF_iAudio='.$progF_iAudio.'&progF_pidtype1='.$progF_pidtype1.'&progF_pid1='.$progF_pid1.'&progF_pidtype2='.$progF_pidtype2.'&progF_pid2='.$progF_pid2.'&progF_pidtype3='.$progF_pidtype3.'&progF_pid3='.$progF_pid3.'&progF_pidtype1Act='.$progF_pidtype1Act.'&progF_pid1Text='.$progF_pid1Text.'&progF_pid1Sel='.$progF_pid1Sel.'&progF_bPid1='.$progF_bPid1.'&progF_thr1='.$progF_thr1.'&progF_bmPid1='.$progF_bmPid1.'&progF_mthr1='.$progF_mthr1.'&progF_pidtype2Act='.$progF_pidtype2Act.'&progF_pid2Text='.$progF_pid2Text.'&progF_pid2Sel='.$progF_pid2Sel.'&progF_bPid2='.$progF_bPid2.'&progF_thr2='.$progF_thr2.'&progF_bmPid2='.$progF_bmPid2.'&progF_mthr2='.$progF_mthr2.'&progF_pidtype3Act='.$progF_pidtype3Act.'&progF_pid3Text='.$progF_pid3Text.'&progF_pid3Sel='.$progF_pid3Sel.'&progF_bPid3='.$progF_bPid3.'&progF_thr3='.$progF_thr3.'&progF_bmPid3='.$progF_bmPid3.'&progF_mthr3='.$progF_mthr3.'&progF_Ovideo='.$progF_Ovideo.'&progF_ovidpid='.$progF_ovidpid.'&progF_video='.$progF_video.'&progF_vidpid='.$progF_vidpid.'&progF_mvideo='.$progF_mvideo.'&progF_mvidpid='.$progF_mvidpid.'&progF_OAudio='.$progF_OAudio.'&progF_oaudpid='.$progF_oaudpid.'&progF_audio='.$progF_audio.'&progF_audpid='.$progF_audpid.'&progF_maudio='.$progF_maudio.'&progF_maudpid='.$progF_maudpid.'&progF_pmt='.$progF_pmt.'&progF_pcr='.$progF_pcr;

    $self->{mech}->get( "http://".$self->{PAGE_IP}.$url_string );
}
# }}}
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
# {{{ pat_mdi_mlr_check
sub pat_mdi_mlr_check {

    my $self = shift;

    my $template = $_[0];
    my $mdi_mlr_value = $_[1];

    my $check_return = $self->check_program_template_value( $template, 'progF_mlr', $mdi_mlr_value );

    return $check_return;
}
# }}}
# {{{ pat_pmla_mlt15
sub pat_pmla_mlt15 {

    my $self = shift;

    my $template = $_[0];
    my $enable_disable = $_[1]; # 1=on, 0=off
    my $new_val = $_[2];

    my $programFault_list_number = $self->get_programFault_list_number( $template );

    my $url_string = '/prot/videoprogramfault.html?programFault_list='.$programFault_list_number.'&programFault_submit=Add%2FUpdate&programFault_template='.$template.'&bpfMLoss15='.$enable_disable.'&progF_ccloss='.$new_val;

    $self->{mech}->get( "http://".$self->{PAGE_IP}.$url_string );
}
# }}}
# {{{ pat_pmla_mlt15_check
sub pat_pmla_mlt15_check {

    my $self = shift;

    my $template = $_[0];
    my $check_box_value = $_[1];
    my $check_value = $_[2];

    my $final_return = "OK";

    my $check_return_checkbox = $self->check_program_template_checkbox( $template, 'bpfMLoss15', $check_box_value );

    my $check_return_val = $self->check_program_template_value( $template, 'progF_ccloss', $check_value );
#print $check_return_checkbox . " - " . $check_return_val . "\n";
    if( $check_return_checkbox eq "Not OK" || $check_return_val eq "Not OK" ){
        $final_return = "Not OK"
    }

    return $final_return;
}
# }}}
# {{{ pat_pmla_mls_lp
sub pat_pmla_mls_lp {

    my $self = shift;

    my $template = $_[0];
    my $enable_disable = $_[1];
    my $new_val = $_[2];

    my $programFault_list_number = $self->get_programFault_list_number( $template );

    my $url_string = '/prot/videoprogramfault.html?programFault_list='.$programFault_list_number.'&programFault_submit=Add%2FUpdate&programFault_template='.$template.'&bpfMLp='.$enable_disable.'&progF_Lp='.$new_val;

    $self->{mech}->get( "http://".$self->{PAGE_IP}.$url_string );
}
# }}}
# {{{ pat_pmla_mls_lp_check
sub pat_pmla_mls_lp_check {

    my $self = shift;

    my $template = $_[0];
    my $check_box_value = $_[1];
    my $check_value = $_[2];

    my $final_return = "OK";

    my $check_return_checkbox = $self->check_program_template_checkbox( $template, 'bpfMLp', $check_box_value );

    my $check_return_val = $self->check_program_template_value( $template, 'progF_Lp', $check_value );

    if( $check_return_checkbox eq "Not OK" || $check_return_val eq "Not OK" ){
        $final_return = "Not OK"
    }

    return $final_return;
}
# }}}
# {{{ pat_pmla_mlt24
sub pat_pmla_mlt24 {

    my $self = shift;

    my $template = $_[0];
    my $enable_disable = $_[1];
    my $new_val = $_[2];

    my $programFault_list_number = $self->get_programFault_list_number( $template );

    my $url_string = '/prot/videoprogramfault.html?programFault_list='.$programFault_list_number.'&programFault_submit=Add%2FUpdate&programFault_template='.$template.'&bpfMLoss='.$enable_disable.'&progF_loss24='.$new_val;

    $self->{mech}->get( "http://".$self->{PAGE_IP}.$url_string );
}
# }}}
# {{{ pat_pmla_mlt24_check
sub pat_pmla_mlt24_check {

    my $self = shift;

    my $template = $_[0];
    my $check_box_value = $_[1];
    my $check_value = $_[2];

    my $final_return = "OK";

    my $check_return_checkbox = $self->check_program_template_checkbox( $template, 'bpfMLoss', $check_box_value );

    my $check_return_val = $self->check_program_template_value( $template, 'progF_loss24', $check_value );

    if( $check_return_checkbox eq "Not OK" || $check_return_val eq "Not OK" ){
        $final_return = "Not OK"
    }

    return $final_return;
}
# }}}
# {{{ pat_pmla_mls_ld
sub pat_pmla_mls_ld {

    my $self = shift;

    my $template = $_[0];
    my $enable_disable = $_[1];
    my $new_val = $_[2];

    my $programFault_list_number = $self->get_programFault_list_number( $template );

    my $url_string = '/prot/videoprogramfault.html?programFault_list='.$programFault_list_number.'&programFault_submit=Add%2FUpdate&programFault_template='.$template.'&bpfMLd='.$enable_disable.'&progF_Ld='.$new_val;

    $self->{mech}->get( "http://".$self->{PAGE_IP}.$url_string );
}
# }}}
# {{{ pat_pmla_mls_ld_check
sub pat_pmla_mls_ld_check {

    my $self = shift;

    my $template = $_[0];
    my $check_box_value = $_[1];
    my $check_value = $_[2];

    my $final_return = "OK";

    my $check_return_checkbox = $self->check_program_template_checkbox( $template, 'bpfMLd', $check_box_value );

    my $check_return_val = $self->check_program_template_value( $template, 'progF_Ld', $check_value );

    if( $check_return_checkbox eq "Not OK" || $check_return_val eq "Not OK" ){
        $final_return = "Not OK"
    }

    return $final_return;
}
# }}}
# {{{ pat_pmla_mls24
sub pat_pmla_mls24 {

    my $self = shift;

    my $template = $_[0];
    my $enable_disable = $_[1]; # 1 on, 0 off
    my $new_val = $_[2];

    my $programFault_list_number = $self->get_programFault_list_number( $template );

    my $url_string = '/prot/videoprogramfault.html?programFault_list='.$programFault_list_number.'&programFault_submit=Add%2FUpdate&programFault_template='.$template.'&bpfMls24='.$enable_disable.'&progF_mls24='.$new_val;

#my $url_string = '/prot/videoprogramfault.html?programFault_list='.$programFault_list_number.'&programFault_template='.$template.'&bpfMls24='.$enable_disable.'&progF_mls24='.$new_val;

#print $url_string."\n";

    $self->{mech}->get( "http://".$self->{PAGE_IP}.$url_string );
}
# }}}
# {{{ pat_pmla_mls24_check
sub pat_pmla_mls24_check {

    my $self = shift;

    my $template = $_[0];
    my $check_box_value = $_[1];
    my $check_value = $_[2];

    my $final_return = "OK";

    my $check_return_checkbox = $self->check_program_template_checkbox( $template, 'bpfMls24', $check_box_value );

    my $check_return_val = $self->check_program_template_value( $template, 'progF_mls24', $check_value );

    if( $check_return_checkbox eq "Not OK" || $check_return_val eq "Not OK" ){
        $final_return = "Not OK"
    }

    return $final_return;
}
# }}}
# {{{ pat_pmla_mls15
sub pat_pmla_mls15 {

    my $self = shift;

    my $template = $_[0];
    my $enable_disable = $_[1];
    my $new_val = $_[2];

    my $programFault_list_number = $self->get_programFault_list_number( $template );

    my $url_string = '/prot/videoprogramfault.html?programFault_list='.$programFault_list_number.'&programFault_submit=Add%2FUpdate&programFault_template='.$template.'&bpfMls15='.$enable_disable.'&progF_mls15='.$new_val;

#my $url_string = '/prot/videoprogramfault.html?programFault_list='.$programFault_list_number.'&programFault_submit=Add%2FUpdate&bpfMls15='.$enable_disable.'&progF_mls15='.$new_val;

#print $url_string."\n";
    $self->{mech}->get( "http://".$self->{PAGE_IP}.$url_string );
}
# }}}
# {{{ pat_pmla_mls15_check
sub pat_pmla_mls15_check {

    my $self = shift;

    my $template = $_[0];
    my $check_box_value = $_[1];
    my $check_value = $_[2];

    my $final_return = "OK";

    my $check_return_checkbox = $self->check_program_template_checkbox( $template, 'bpfMls15', $check_box_value );

    my $check_return_val = $self->check_program_template_value( $template, 'progF_mls15', $check_value );

    if( $check_return_checkbox eq "Not OK" || $check_return_val eq "Not OK" ){
        $final_return = "Not OK"
    }

    return $final_return;
}
# }}}
# {{{ edit_pat_pma_program_scramble_state
sub edit_pat_pma_program_scramble_state {

    my $self = shift;

    my $template = $_[0];
    my $enable_disable = $_[1];
    my $new_val = $_[2];

    my $programFault_list_number = $self->get_programFault_list_number( $template );

    my $url_string = '/prot/videoprogramfault.html?programFault_list='.$programFault_list_number.'&programFault_submit=Add%2FUpdate&programFault_template='.$template.'&progF_bscramble='.$enable_disable.'&progF_scramble='.$new_val;

    $self->{mech}->get( "http://".$self->{PAGE_IP}.$url_string );
}
# }}}
# {{{ edit_pat_pma_program_scramble_state_check
sub edit_pat_pma_program_scramble_state_check {

    my $self = shift;

    my $template = $_[0];
    my $check_box_value = $_[1];
    my $check_value = $_[2];

    my $final_return = "OK";

    my $check_return_checkbox = $self->check_program_template_checkbox( $template, 'progF_bscramble', $check_box_value );

    my $check_return_val = $self->check_program_template_selectbox( $template, 'progF_scramble', $check_value );

    if( $check_return_checkbox eq "Not OK" || $check_return_val eq "Not OK" ){
        $final_return = "Not OK"
    }

    return $final_return;
}
# }}}
# {{{ edit_pat_pma_pid_monitor_status
sub edit_pat_pma_pid_monitor_status {

    my $self = shift;

    my $template = $_[0];
    my $new_val = $_[1];

    my $programFault_list_number = $self->get_programFault_list_number( $template );

    my $url_string = '/prot/videoprogramfault.html?programFault_list='.$programFault_list_number.'&programFault_submit=Add%2FUpdate&programFault_template='.$template.'&progF_control='.$new_val;

    $self->{mech}->get( "http://".$self->{PAGE_IP}.$url_string );
}
# }}}
# {{{ edit_pat_pma_pid_monitor_status_check
sub edit_pat_pma_pid_monitor_status_check{

    my $self = shift;

    my $template = $_[0];
    my $check_value = $_[1];

    my $final_return = "OK";

    $final_return = $self->check_program_template_selectbox( $template, 'progF_control', $check_value );

    return $final_return;
}
# }}}
# {{{ edit_pat_pma_pid_alarm_trigger_period
sub edit_pat_pma_pid_alarm_trigger_period {

    my $self = shift;

    my $template = $_[0];
    my $new_val = $_[1]; 
    
    my $programFault_list_number = $self->get_programFault_list_number( $template );

    my $url_string = '/prot/videoprogramfault.html?programFault_list='.$programFault_list_number.'&programFault_submit=Add%2FUpdate&programFault_template='.$template.'&progF_soak='.$new_val;
    
    $self->{mech}->get( "http://".$self->{PAGE_IP}.$url_string );
}
# }}}
# {{{ edit_pat_pma_pid_alarm_trigger_period_check
sub edit_pat_pma_pid_alarm_trigger_period_check {

    my $self = shift;

    my $template = $_[0];
    my $check_value = $_[1];

    my $final_return = "OK";

    my $final_return = $self->check_program_template_value( $template, 'progF_soak', $check_value );

    return $final_return;
}
# }}}
# {{{ edit_pat_pma_ignore_secondary_audio_pid
sub edit_pat_pma_ignore_secondary_audio_pid {

    my $self = shift;

    my $template = $_[0];
    my $new_val = $_[1];

    my $programFault_list_number = $self->get_programFault_list_number( $template );

    my $url_string = '/prot/videoprogramfault.html?programFault_list='.$programFault_list_number.'&programFault_submit=Add%2FUpdate&programFault_template='.$template.'&progF_iAudio='.$new_val;
    
    $self->{mech}->get( "http://".$self->{PAGE_IP}.$url_string );
}
# }}}
# {{{ edit_pat_pma_ignore_secondary_audio_pid_check
sub edit_pat_pma_ignore_secondary_audio_pid_check {

    my $self = shift;

    my $template = $_[0];
    my $check_value = $_[1];

    my $final_return = "OK";

    my $final_return = $self->check_program_template_checkbox( $template, 'progF_iAudio', $check_value );

    return $final_return;
}
# }}}
# {{{ edit_pat_pma_scte35_detection
sub edit_pat_pma_scte35_detection {

    my $self = shift;

    my $template = $_[0];
    my $new_val = $_[1];

    my $programFault_list_number = $self->get_programFault_list_number( $template );

    my $url_string = '/prot/videoprogramfault.html?programFault_list='.$programFault_list_number.'&programFault_submit=Add%2FUpdate&programFault_template='.$template.'&progF_bScte='.$new_val;

    $self->{mech}->get( "http://".$self->{PAGE_IP}.$url_string );
}
# }}}
# {{{ edit_pat_pma_max_inactivity_period_scte35 
sub edit_pat_pma_max_inactivity_period_scte35 {

    my $self = shift;

    my $template = $_[0];
    my $enable_disable = $_[1];
    my $new_val = $_[2];

    my $programFault_list_number = $self->get_programFault_list_number( $template );

    my $url_string = '/prot/videoprogramfault.html?programFault_list='.$programFault_list_number.'&programFault_submit=Add%2FUpdate&programFault_template='.$template.'&progF_bScteIvl='.$enable_disable.'&progF_ScteIvl='.$new_val;

    $self->{mech}->get( "http://".$self->{PAGE_IP}.$url_string );
}
# }}}
# {{{ edit_ppbma_video_outage_val
sub edit_ppbma_video_outage_val {

    my $self = shift;

    my $template = $_[0];
    my $enable_disable = $_[1];
    my $new_val = $_[2];

    my $programFault_list_number = $self->get_programFault_list_number( $template );

    my $url_string = '/prot/videoprogramfault.html?programFault_list='.$programFault_list_number.'&programFault_submit=Add%2FUpdate&programFault_template='.$template.'&progF_Ovideo='.$enable_disable.'&progF_ovidpid='.$new_val;

    $self->{mech}->get( "http://".$self->{PAGE_IP}.$url_string );
}
# }}}
# {{{ edit_ppbma_video_outage_val_check
sub edit_ppbma_video_outage_val_check {

    my $self = shift;

    my $template = $_[0];
    my $check_box_value = $_[1];
    my $check_value = $_[2];

    my $final_return = "OK";

    my $check_return_checkbox = $self->check_program_template_checkbox( $template, 'progF_Ovideo', $check_box_value );

    my $check_return_val = $self->check_program_template_value( $template, 'progF_ovidpid', $check_value );

    if( $check_return_checkbox eq "Not OK" || $check_return_val eq "Not OK" ){
        $final_return = "Not OK"
    }

    return $final_return;
}
# }}}
# {{{ edit_ppbma_video_min_val
sub edit_ppbma_video_min_val {

    my $self = shift;

    my $template = $_[0];
    my $enable_disable = $_[1];
    my $new_val = $_[2];

    my $programFault_list_number = $self->get_programFault_list_number( $template );

    my $url_string = '/prot/videoprogramfault.html?programFault_list='.$programFault_list_number.'&programFault_submit=Add%2FUpdate&programFault_template='.$template.'&progF_video='.$enable_disable.'&progF_vidpid='.$new_val;

    $self->{mech}->get( "http://".$self->{PAGE_IP}.$url_string );
}
# }}}
# {{{ edit_ppbma_video_min_val_check
sub edit_ppbma_video_min_val_check {

    my $self = shift;

    my $template = $_[0];
    my $check_box_value = $_[1];
    my $check_value = $_[2];

    my $final_return = "OK";

    my $check_return_checkbox = $self->check_program_template_checkbox( $template, 'progF_video', $check_box_value );

    my $check_return_val = $self->check_program_template_value( $template, 'progF_vidpid', $check_value );

    if( $check_return_checkbox eq "Not OK" || $check_return_val eq "Not OK" ){
        $final_return = "Not OK"
    }

    return $final_return;
}
# }}}
# {{{ edit_ppbma_video_max_val 
sub edit_ppbma_video_max_val {

    my $self = shift;

    my $template = $_[0];
    my $enable_disable = $_[1];
    my $new_val = $_[2];

    my $programFault_list_number = $self->get_programFault_list_number( $template );

    my $url_string = '/prot/videoprogramfault.html?programFault_list='.$programFault_list_number.'&programFault_submit=Add%2FUpdate&programFault_template='.$template.'&progF_mvideo='.$enable_disable.'&progF_mvidpid='.$new_val;

    $self->{mech}->get( "http://".$self->{PAGE_IP}.$url_string );
}
# }}}
# {{{ edit_ppbma_video_max_val_check
sub edit_ppbma_video_max_val_check {

    my $self = shift;

    my $template = $_[0];
    my $check_box_value = $_[1];
    my $check_value = $_[2];

    my $final_return = "OK";

    my $check_return_checkbox = $self->check_program_template_checkbox( $template, 'progF_mvideo', $check_box_value );

    my $check_return_val = $self->check_program_template_value( $template, 'progF_mvidpid', $check_value );

    if( $check_return_checkbox eq "Not OK" || $check_return_val eq "Not OK" ){
        $final_return = "Not OK"
    }

    return $final_return;
}
# }}}
# {{{ edit_ppbma_audo_outage_val
sub edit_ppbma_audo_outage_val {

    my $self = shift;

    my $template = $_[0];
    my $enable_disable = $_[1];
    my $new_val = $_[2];

    my $programFault_list_number = $self->get_programFault_list_number( $template );

    my $url_string = '/prot/videoprogramfault.html?programFault_list='.$programFault_list_number.'&programFault_submit=Add%2FUpdate&programFault_template='.$template.'&progF_OAudio='.$enable_disable.'&progF_oaudpid='.$new_val;

    $self->{mech}->get( "http://".$self->{PAGE_IP}.$url_string );
}
# }}}
# {{{ edit_ppbma_audo_outage_val_check
sub edit_ppbma_audo_outage_val_check {

    my $self = shift;

    my $template = $_[0];
    my $check_box_value = $_[1];
    my $check_value = $_[2];

    my $final_return = "OK";

    my $check_return_checkbox = $self->check_program_template_checkbox( $template, 'progF_OAudio', $check_box_value );

    my $check_return_val = $self->check_program_template_value( $template, 'progF_oaudpid', $check_value );

    if( $check_return_checkbox eq "Not OK" || $check_return_val eq "Not OK" ){
        $final_return = "Not OK"
    }

    return $final_return;
}
# }}}
# {{{ edit_ppbma_audio_min_val
sub edit_ppbma_audio_min_val {

    my $self = shift;

    my $template = $_[0];
    my $enable_disable = $_[1];
    my $new_val = $_[2];

    my $programFault_list_number = $self->get_programFault_list_number( $template );

    my $url_string = '/prot/videoprogramfault.html?programFault_list='.$programFault_list_number.'&programFault_submit=Add%2FUpdate&programFault_template='.$template.'&progF_audio='.$enable_disable.'&progF_audpid='.$new_val;

    $self->{mech}->get( "http://".$self->{PAGE_IP}.$url_string );
}
# }}}
# {{{ edit_ppbma_audio_min_val_check
sub edit_ppbma_audio_min_val_check {

    my $self = shift;

    my $template = $_[0];
    my $check_box_value = $_[1];
    my $check_value = $_[2];

    my $final_return = "OK";

    my $check_return_checkbox = $self->check_program_template_checkbox( $template, 'progF_audio', $check_box_value );

    my $check_return_val = $self->check_program_template_value( $template, 'progF_audpid', $check_value );

    if( $check_return_checkbox eq "Not OK" || $check_return_val eq "Not OK" ){
        $final_return = "Not OK"
    }

    return $final_return;
}
# }}}
# {{{ edit_ppbma_audio_max_val
sub edit_ppbma_audio_max_val {

    my $self = shift;

    my $template = $_[0];
    my $enable_disable = $_[1];
    my $new_val = $_[2];

    my $programFault_list_number = $self->get_programFault_list_number( $template );

    my $url_string = '/prot/videoprogramfault.html?programFault_list='.$programFault_list_number.'&programFault_submit=Add%2FUpdate&programFault_template='.$template.'&progF_maudio='.$enable_disable.'&progF_maudpid='.$new_val;

    $self->{mech}->get( "http://".$self->{PAGE_IP}.$url_string );
}
# }}}
# {{{ edit_ppbma_audio_max_val_check
sub edit_ppbma_audio_max_val_check {

    my $self = shift;

    my $template = $_[0];
    my $check_box_value = $_[1];
    my $check_value = $_[2];

    my $final_return = "OK";

    my $check_return_checkbox = $self->check_program_template_checkbox( $template, 'progF_maudio', $check_box_value );

    my $check_return_val = $self->check_program_template_value( $template, 'progF_maudpid', $check_value );

    if( $check_return_checkbox eq "Not OK" || $check_return_val eq "Not OK" ){
        $final_return = "Not OK"
    }

    return $final_return;
}
# }}}
# {{{ edit_ppbma_pmt_pid_outage
sub edit_ppbma_pmt_pid_outage {

    my $self = shift;
    
    my $template = $_[0];
    my $new_val = $_[1];
    
    my $programFault_list_number = $self->get_programFault_list_number( $template );

    my $url_string = '/prot/videoprogramfault.html?programFault_list='.$programFault_list_number.'&programFault_submit=Add%2FUpdate&programFault_template='.$template.'&progF_pmt='.$new_val;
    
    $self->{mech}->get( "http://".$self->{PAGE_IP}.$url_string );
}
# }}}
# {{{ edit_ppbma_pmt_pid_outage_check
sub edit_ppbma_pmt_pid_outage_check {

    my $self = shift;

    my $template = $_[0];
    my $check_box_value = $_[1];
    my $check_value = $_[2];

    my $final_return = "OK";

    my $final_return = $self->check_program_template_value( $template, 'progF_pmt', $check_box_value );

    return $final_return;
}
# }}}
# {{{ edit_ppbma_pmt_pcr_pid_outage
sub edit_ppbma_pmt_pcr_pid_outage {

    my $self = shift;
 
    my $template = $_[0];
    my $new_val = $_[1];

    my $programFault_list_number = $self->get_programFault_list_number( $template );

    my $url_string = '/prot/videoprogramfault.html?programFault_list='.$programFault_list_number.'&programFault_submit=Add%2FUpdate&programFault_template='.$template.'&progF_pcr='.$new_val;

    $self->{mech}->get( "http://".$self->{PAGE_IP}.$url_string );
}
# }}}
# {{{ edit_ppbma_pmt_pcr_pid_outage_check
sub edit_ppbma_pmt_pcr_pid_outage_check {

    my $self = shift;

    my $template = $_[0];
    my $check_box_value = $_[1];
    my $check_value = $_[2];

    my $final_return = "OK";

    my $final_return = $self->check_program_template_value( $template, 'progF_pcr', $check_box_value );

    return $final_return;
}
# }}}
# Transport Flow Alarms Settings - IP/RTP Loss Alarms
# {{{ transport_alarm_template_add
sub transport_alarm_template_add{

    my $self = shift;

    my $videoTs_list = $_[0];
    my $videochar_submit = $_[1];
    my $videoTs_name = $_[2];
    my $sF_bProgCount = $_[3];
    my $sF_progCount = $_[4];
    my $videoTs_bAlign = $_[5];
    my $bsfRtplp = $_[6];
    my $sF_rtplp = $_[7];
    my $bsfRtpld = $_[8];
    my $sF_rtpld = $_[9];
    my $bsfRtptotloss = $_[10];
    my $sF_rtptotloss = $_[11];
    my $bsfRtploss24 = $_[12];
    my $sF_rtploss24 = $_[13];
    my $bsfls15 = $_[14];
    my $sF_ls15 = $_[15];
    my $bsfls24 = $_[16];
    my $sF_ls24 = $_[17];
    my $bsfMdi = $_[18];
    my $sF_mdi = $_[19];
    my $bsfVb = $_[20];
    my $sF_VB = $_[21];
    my $bsfLve = $_[22];
    my $sF_lve = $_[23];
    my $bsfZap = $_[24];
    my $sF_zap = $_[25];
    my $sF_bitDev = $_[26];
    my $bsfMaxBit = $_[27];
    my $bsfmaxbps = $_[28];
    my $sF_maxbps = $_[29];
    my $bsfminbps = $_[30];
    my $sF_minbps = $_[31];
    my $sF_out = $_[32];
    my $videoTs_svcname = $_[33];
    my $videoTs_timeout = $_[34];
    my $videoTs_encoder = $_[35];
    my $videoTs_bittype = $_[36];
    my $videoTs_bitstatus = $_[37];
    my $videoTs_bitrate = $_[38];
    my $videoTs_bPcrBit = $_[39];
    my $videoTs_pcrbit = $_[40];
    my $videoTs_bUnref = $_[41];
    my $videoTs_bSync = $_[42];
    my $videoTs_pat = $_[43];
    my $videoTs_ProgChg = $_[44];
    my $videoTs_ProgRem = $_[45];
    my $videoTs_stuff = $_[46];
    my $videoTs_stuffpid = $_[47];
    my $videoTs_mstuff = $_[48];
    my $videoTs_mstuffpid = $_[49];
    my $videoTs_pidtype1 = $_[50];
    my $videoTs_pid1 = $_[51];
    my $videoTs_pidtype2 = $_[52];
    my $videoTs_pid2 = $_[53];
    my $videoTs_pidtype3 = $_[54];
    my $videoTs_pid3 = $_[55];
    my $videoTs_pidtype4 = $_[56];
    my $videoTs_pid4 = $_[57];
    my $alarmTab = $_[58];
    my $videoTs_iAll = $_[59];
    my $sF_mlr = $_[60];
    my $bsfMLp = $_[61];
    my $sF_mlp = $_[62];
    my $bsfMLd = $_[63];
    my $sF_mld = $_[64];
    my $bsfMl15 = $_[65];
    my $sF_ccloss = $_[66];
    my $bsfMl24 = $_[67];
    my $sF_mloss24 = $_[68];
    my $bsfMls15 = $_[69];
    my $sF_mls15 = $_[70];
    my $bsfMls24 = $_[71];
    my $sF_mls24 = $_[72];
    my $videoTs_pidtype1Act = $_[73];
    my $videoTs_pid1Text = $_[74];
    my $videoTs_pid1Sel = $_[75];
    my $videoTs_pidtype2Act = $_[76];
    my $videoTs_pid2Text = $_[77];
    my $videoTs_pid2Sel = $_[78];
    my $videoTs_pidtype3Act = $_[79];
    my $videoTs_pid3Text = $_[80];
    my $videoTs_pid3Sel = $_[81];
    my $videoTs_pidtype4Act = $_[82];
    my $videoTs_pid4Text = $_[83];
    my $videoTs_pid4Sel = $_[84];
    my $videoTs_bffrew = $_[85];
    my $videoTs_ffrew = $_[86];
    my $videoTs_fftype = $_[87];
    my $etrName = $_[88];
    my $etr11 = $_[89];
    my $etr12 = $_[90];
    my $etr13 = $_[91];
    my $letr13 = $_[92];
    my $etr14 = $_[93];
    my $etr15 = $_[94];
    my $letr15 = $_[95];
    my $etr16a = $_[96];
    my $petr16a = $_[97];
    my $letr16a = $_[98];
    my $etr16b = $_[99];
    my $petr16b = $_[100];
    my $letr16b = $_[101];
    my $etr16c = $_[102];
    my $petr16c = $_[103];
    my $letr16c = $_[104];
    my $etr16d = $_[105];
    my $petr16d = $_[106];
    my $letr16d = $_[107];
    my $etr21 = $_[108];
    my $etr22 = $_[109];
    my $etr23 = $_[110];
    my $letr23a = $_[111];
    my $letr23b = $_[112];
    my $etr24 = $_[113];
    my $letr24 = $_[114];
    my $etr25 = $_[115];
    my $letr25 = $_[116];
    my $etr26 = $_[117];

    my $url_string = '/prot/videoalarm.html?videoTs_list='.$videoTs_list.'&videochar_submit=Add%2FUpdate&videoTs_name='.$videoTs_name.'&sF_bProgCount='.$sF_bProgCount.'&sF_progCount='.$sF_progCount.'&videoTs_bAlign='.$videoTs_bAlign.'&bsfRtplp='.$bsfRtplp.'&sF_rtplp='.$sF_rtplp.'&bsfRtpld='.$bsfRtpld.'&sF_rtpld='.$sF_rtpld.'&bsfRtptotloss='.$bsfRtptotloss.'&sF_rtptotloss='.$sF_rtptotloss.'&bsfRtploss24='.$bsfRtploss24.'&sF_rtploss24='.$sF_rtploss24.'&bsfls15='.$bsfls15.'&sF_ls15='.$sF_ls15.'&bsfls24='.$bsfls24.'&sF_ls24='.$sF_ls24.'&bsfMdi='.$bsfMdi.'&sF_mdi='.$sF_mdi.'&bsfVb='.$bsfVb.'&sF_VB='.$sF_VB.'&bsfLve='.$bsfLve.'&sF_lve='.$sF_lve.'&bsfZap='.$bsfZap.'&sF_zap='.$sF_zap.'&sF_bitDev='.$sF_bitDev.'&bsfMaxBit='.$bsfMaxBit.'&bsfmaxbps='.$bsfmaxbps.'&sF_maxbps='.$sF_maxbps.'&bsfminbps='.$bsfminbps.'&sF_minbps='.$sF_minbps.'&sF_out='.$sF_out.'&videoTs_svcname='.$videoTs_svcname.'&videoTs_timeout='.$videoTs_timeout.'&videoTs_encoder='.$videoTs_encoder.'&videoTs_bittype='.$videoTs_bittype.'&videoTs_bitstatus='.$videoTs_bitstatus.'&videoTs_bitrate='.$videoTs_bitrate.'&videoTs_bPcrBit='.$videoTs_bPcrBit.'&videoTs_pcrbit='.$videoTs_pcrbit.'&videoTs_bUnref='.$videoTs_bUnref.'&videoTs_bSync='.$videoTs_bSync.'&videoTs_pat='.$videoTs_pat.'&videoTs_ProgChg='.$videoTs_ProgChg.'&videoTs_ProgRem='.$videoTs_ProgRem.'&videoTs_stuff='.$videoTs_stuff.'&videoTs_stuffpid='.$videoTs_stuffpid.'&videoTs_mstuff='.$videoTs_mstuff.'&videoTs_mstuffpid='.$videoTs_mstuffpid.'&videoTs_pidtype1='.$videoTs_pidtype1.'&videoTs_pid1='.$videoTs_pid1.'&videoTs_pidtype2='.$videoTs_pidtype2.'&videoTs_pid2='.$videoTs_pid2.'&videoTs_pidtype3='.$videoTs_pidtype3.'&videoTs_pid3='.$videoTs_pid3.'&videoTs_pidtype4='.$videoTs_pidtype4.'&videoTs_pid4='.$videoTs_pid4.'&alarmTab='.$alarmTab.'&videoTs_iAll='.$videoTs_iAll.'&sF_mlr='.$sF_mlr.'&bsfMLp='.$bsfMLp.'&sF_mlp='.$sF_mlp.'&bsfMLd='.$bsfMLd.'&sF_mld='.$sF_mld.'&bsfMl15='.$bsfMl15.'&sF_ccloss='.$sF_ccloss.'&bsfMl24='.$bsfMl24.'&sF_mloss24='.$sF_mloss24.'&bsfMls15='.$bsfMls15.'&sF_mls15='.$sF_mls15.'&bsfMls24='.$bsfMls24.'&sF_mls24='.$sF_mls24.'&videoTs_pidtype1Act='.$videoTs_pidtype1Act.'&videoTs_pid1Text='.$videoTs_pid1Text.'&videoTs_pid1Sel='.$videoTs_pid1Sel.'&videoTs_pidtype2Act='.$videoTs_pidtype2Act.'&videoTs_pid2Text='.$videoTs_pid2Text.'&videoTs_pid2Sel='.$videoTs_pid2Sel.'&videoTs_pidtype3Act='.$videoTs_pidtype3Act.'&videoTs_pid3Text='.$videoTs_pid3Text.'&videoTs_pid3Sel='.$videoTs_pid3Sel.'&videoTs_pidtype4Act='.$videoTs_pidtype4Act.'&videoTs_pid4Text='.$videoTs_pid4Text.'&videoTs_pid4Sel='.$videoTs_pid4Sel.'&videoTs_bffrew='.$videoTs_bffrew.'&videoTs_ffrew='.$videoTs_ffrew.'&videoTs_fftype='.$videoTs_fftype.'&etrName='.$etrName.'&etr11='.$etr11.'&etr12='.$etr12.'&etr13='.$etr13.'&letr13='.$letr13.'&etr14='.$etr14.'&etr15='.$etr15.'&letr15='.$letr15.'&etr16a='.$etr16a.'&petr16a='.$petr16a.'&letr16a='.$letr16a.'&etr16b='.$etr16b.'&petr16b='.$petr16b.'&letr16b='.$letr16b.'&etr16c='.$etr16c.'&petr16c='.$petr16c.'&letr16c='.$letr16c.'&etr16d='.$etr16d.'&petr16d='.$petr16d.'&letr16d='.$letr16d.'&etr21='.$etr21.'&etr22='.$etr22.'&etr23='.$etr23.'&letr23a='.$letr23a.'&letr23b='.$letr23b.'&etr24='.$etr24.'&letr24='.$letr24.'&etr25='.$etr25.'&letr25='.$letr25.'&etr26='.$etr26;

    $self->{mech}->get( "http://".$self->{PAGE_IP}.$url_string ); 
}
# }}}
# {{{ edit_tat_flow_ip_rtp_loss_alarms_program_loss_alarm_count
sub edit_tat_flow_ip_rtp_loss_alarms_program_loss_alarm_count {

    my $self = shift;

    $self->run_alarm_template_checkbox_and_val( 'transport', 'sF_bProgCount', 'sF_progCount', $_[0], $_[1], $_[2] );
}
# }}}
# {{{ edit_tat_flow_ip_rtp_loss_alarms_program_loss_alarm_count_check
sub edit_tat_flow_ip_rtp_loss_alarms_program_loss_alarm_count_check {

    my $self = shift;

    my $template = $_[0];
    my $check_box_value = $_[1];
    my $check_value = $_[2];

    my $final_return = "OK";

    my $check_return_checkbox = $self->check_transport_template_checkbox( $template, 'sF_bProgCount', $check_box_value );

    my $check_return_val = $self->check_transport_template_value( $template, 'sF_progCount', $check_value );

    if( $check_return_checkbox eq "Not OK" || $check_return_val eq "Not OK" ){
        $final_return = "Not OK"
    }

    return $final_return;
}
# }}}
# {{{ edit_tat_flow_ip_rtp_loss_alarms_ts_algn
sub edit_tat_flow_ip_rtp_loss_alarms_ts_algn {

    my $self = shift;

    $self->run_alarm_template_checkbox_and_val( 'transport', 'videoTs_bAlign', 'none', $_[0], $_[1], '-1' );
}
# }}}
# {{{ edit_tat_flow_ip_rtp_loss_alarms_ts_algn_check
sub edit_tat_flow_ip_rtp_loss_alarms_ts_algn_check {

    my $self = shift;

    my $template = $_[0];
    my $check_box_value = $_[1];
    my $check_value = $_[2];

    my $final_return = "OK";

    $final_return = $self->check_transport_template_checkbox( $template, 'videoTs_bAlign', $check_box_value );

    return $final_return;
}
# }}}
# {{{ edit_tat_flow_ip_rtp_loss_alarms_rtp_lp
sub edit_tat_flow_ip_rtp_loss_alarms_rtp_lp {

    my $self = shift;

    $self->run_alarm_template_checkbox_and_val( 'transport', 'bsfRtplp', 'sF_rtplp', $_[0], $_[1], $_[2] );
}
# }}}
# {{{ edit_tat_flow_ip_rtp_loss_alarms_rtp_lp_check
sub edit_tat_flow_ip_rtp_loss_alarms_rtp_lp_check {

    my $self = shift;

    my $template = $_[0];
    my $check_box_value = $_[1];
    my $check_value = $_[2];

    my $final_return = "OK";

    my $check_return_checkbox = $self->check_transport_template_checkbox( $template, 'bsfRtplp', $check_box_value );

    my $check_return_val = $self->check_transport_template_value( $template, 'sF_rtplp', $check_value );

    if( $check_return_checkbox eq "Not OK" || $check_return_val eq "Not OK" ){
        $final_return = "Not OK"
    }

    return $final_return;
}
# }}}
# {{{ edit_tat_flow_ip_rtp_loss_alarms_rtp_ld
sub edit_tat_flow_ip_rtp_loss_alarms_rtp_ld {

    my $self = shift;

    $self->run_alarm_template_checkbox_and_val( 'transport', 'bsfRtpld', 'sF_rtpld', $_[0], $_[1], $_[2] );
}
# }}}
# {{{ edit_tat_flow_ip_rtp_loss_alarms_rtp_ld_check
sub edit_tat_flow_ip_rtp_loss_alarms_rtp_ld_check {

    my $self = shift;

    my $template = $_[0];
    my $check_box_value = $_[1];
    my $check_value = $_[2];

    my $final_return = "OK";

    my $check_return_checkbox = $self->check_transport_template_checkbox( $template, 'bsfRtpld', $check_box_value );

    my $check_return_val = $self->check_transport_template_value( $template, 'sF_rtpld', $check_value );

    if( $check_return_checkbox eq "Not OK" || $check_return_val eq "Not OK" ){
        $final_return = "Not OK"
    }

    return $final_return;
}
# }}}
# {{{ edit_tat_flow_ip_rtp_loss_alarms_rtp_se15
sub edit_tat_flow_ip_rtp_loss_alarms_rtp_se15 {

    my $self = shift;

    $self->run_alarm_template_checkbox_and_val( 'transport', 'bsfRtptotloss', 'sF_rtptotloss', $_[0], $_[1], $_[2] );
}
# }}}
# {{{ edit_tat_flow_ip_rtp_loss_alarms_rtp_se15_check
sub edit_tat_flow_ip_rtp_loss_alarms_rtp_se15_check {

    my $self = shift;

    my $template = $_[0];
    my $check_box_value = $_[1];
    my $check_value = $_[2];

    my $final_return = "OK";

    my $check_return_checkbox = $self->check_transport_template_checkbox( $template, 'bsfRtptotloss', $check_box_value );

    my $check_return_val = $self->check_transport_template_value( $template, 'sF_rtptotloss', $check_value );

    if( $check_return_checkbox eq "Not OK" || $check_return_val eq "Not OK" ){
        $final_return = "Not OK"
    }

    return $final_return;
}
# }}}
# {{{ edit_tat_flow_ip_rtp_loss_alarms_rtp_se24
sub edit_tat_flow_ip_rtp_loss_alarms_rtp_se24 {

    my $self = shift;

    $self->run_alarm_template_checkbox_and_val( 'transport', 'bsfRtploss24', 'sF_rtploss24', $_[0], $_[1], $_[2] );
}
#}}}
# {{{ edit_tat_flow_ip_rtp_loss_alarms_rtp_se24_check
sub edit_tat_flow_ip_rtp_loss_alarms_rtp_se24_check {

    my $self = shift;

    my $template = $_[0];
    my $check_box_value = $_[1];
    my $check_value = $_[2];

    my $final_return = "OK";

    my $check_return_checkbox = $self->check_transport_template_checkbox( $template, 'bsfRtploss24', $check_box_value );

    my $check_return_val = $self->check_transport_template_value( $template, 'sF_rtploss24', $check_value );

    if( $check_return_checkbox eq "Not OK" || $check_return_val eq "Not OK" ){
        $final_return = "Not OK"
    }

    return $final_return;
}
# }}}
# {{{ edit_tat_flow_ip_rtp_loss_alarms_rtp_ls15
sub edit_tat_flow_ip_rtp_loss_alarms_rtp_ls15 {

    my $self = shift;

    $self->run_alarm_template_checkbox_and_val( 'transport', 'bsfls15', 'sF_ls15', $_[0], $_[1], $_[2] );
}
# }}}
# {{{ edit_tat_flow_ip_rtp_loss_alarms_rtp_ls15_check
sub edit_tat_flow_ip_rtp_loss_alarms_rtp_ls15_check {

    my $self = shift;

    my $template = $_[0];
    my $check_box_value = $_[1];
    my $check_value = $_[2];

    my $final_return = "OK";

    my $check_return_checkbox = $self->check_transport_template_checkbox( $template, 'bsfls15', $check_box_value );

    my $check_return_val = $self->check_transport_template_value( $template, 'sF_ls15', $check_value );

    if( $check_return_checkbox eq "Not OK" || $check_return_val eq "Not OK" ){
        $final_return = "Not OK"
    }

    return $final_return;
}
# }}}
# {{{ edit_tat_flow_ip_rtp_loss_alarms_rtp_ls24
sub edit_tat_flow_ip_rtp_loss_alarms_rtp_ls24 {

    my $self = shift;

    $self->run_alarm_template_checkbox_and_val( 'transport', 'bsfls24', 'sF_ls24', $_[0], $_[1], $_[2] );
}
# }}}
# {{{ edit_tat_flow_ip_rtp_loss_alarms_rtp_ls24_check
sub edit_tat_flow_ip_rtp_loss_alarms_rtp_ls24_check {

    my $self = shift;

    my $template = $_[0];
    my $check_box_value = $_[1];
    my $check_value = $_[2];

    my $final_return = "OK";

    my $check_return_checkbox = $self->check_transport_template_checkbox( $template, 'bsfls24', $check_box_value );

    my $check_return_val = $self->check_transport_template_value( $template, 'sF_ls24', $check_value );

    if( $check_return_checkbox eq "Not OK" || $check_return_val eq "Not OK" ){
        $final_return = "Not OK"
    }

    return $final_return;
}
# }}}
# {{{ edit_tat_flow_ip_rtp_loss_alarms_rtp_dup
sub edit_tat_flow_ip_rtp_loss_alarms_rtp_dup {

    my $self = shift;
    $self->run_alarm_template_checkbox_and_val( 'transport', 'sF_rtpDup', 'none', $_[0], $_[1], '-1' );
}
# }}}
# {{{ edit_tat_flow_ip_rtp_loss_alarms_rtp_dup_check
sub edit_tat_flow_ip_rtp_loss_alarms_rtp_dup_check {

    my $self = shift;

    my $template = $_[0];
    my $check_box_value = $_[1];
    my $check_value = $_[2];

    my $final_return = "OK";

    my $final_return = $self->check_transport_template_checkbox( $template, 'sF_rtpDup', $check_box_value );

    return $final_return;
}
# }}}
# {{{ edit_tat_flow_ip_rtp_loss_alarms_rtp_oos
sub edit_tat_flow_ip_rtp_loss_alarms_rtp_oos {

    my $self = shift;
    $self->run_alarm_template_checkbox_and_val( 'transport', 'sF_rtpOos', 'none', $_[0], $_[1], '-1' );
}
# }}}
# {{{ edit_tat_flow_ip_rtp_loss_alarms_rtp_oos_check
sub edit_tat_flow_ip_rtp_loss_alarms_rtp_oos_check {

    my $self = shift;

    my $template = $_[0];
    my $check_box_value = $_[1];
    my $check_value = $_[2];

    my $final_return = "OK";

    my $final_return = $self->check_transport_template_checkbox( $template, 'sF_rtpOos', $check_box_value );

    return $final_return;
}
# }}}
# Transport Flow Alarms Settings - Packet Arrival Time
# {{{ edit_tat_flow_pat_mdi_df
sub edit_tat_flow_pat_mdi_df {

    my $self = shift;

    $self->run_alarm_template_checkbox_and_val( 'transport', 'bsfMdi', 'sF_mdi', $_[0], $_[1], $_[2] );
}
# }}}
# {{{ edit_tat_flow_pat_mdi_df_check
sub edit_tat_flow_pat_mdi_df_check {

    my $self = shift;

    my $template = $_[0];
    my $check_box_value = $_[1];
    my $check_value = $_[2];

    my $final_return = "OK";

    my $check_return_checkbox = $self->check_transport_template_checkbox( $template, 'bsfMdi', $check_box_value );

    my $check_return_val = $self->check_transport_template_value( $template, 'sF_mdi', $check_value );

    if( $check_return_checkbox eq "Not OK" || $check_return_val eq "Not OK" ){
        $final_return = "Not OK"
    }

    return $final_return;
}
# }}}
# {{{ edit_tat_flow_pat_mdi_vbuf
sub edit_tat_flow_pat_mdi_vbuf {

    my $self = shift;

    $self->run_alarm_template_checkbox_and_val( 'transport', 'bsfVb', 'sF_VB', $_[0], $_[1], $_[2] );
}
# }}}
# {{{ edit_tat_flow_pat_mdi_vbuf_check
sub edit_tat_flow_pat_mdi_vbuf_check {

    my $self = shift;

    my $template = $_[0];
    my $check_box_value = $_[1];
    my $check_value = $_[2];

    my $final_return = "OK";

    my $check_return_checkbox = $self->check_transport_template_checkbox( $template, 'bsfVb', $check_box_value );

    my $check_return_val = $self->check_transport_template_value( $template, 'sF_VB', $check_value );

    if( $check_return_checkbox eq "Not OK" || $check_return_val eq "Not OK" ){
        $final_return = "Not OK"
    }

    return $final_return;
}
# }}}
# {{{ edit_tat_flow_pat_igmp_lve
sub edit_tat_flow_pat_igmp_lve {

    my $self = shift;

    $self->run_alarm_template_checkbox_and_val( 'transport', 'bsfLve', 'sF_lve', $_[0], $_[1], $_[2] );
}
# }}}
# {{{ edit_tat_flow_pat_igmp_lve_check
sub edit_tat_flow_pat_igmp_lve_check {

    my $self = shift;

    my $template = $_[0];
    my $check_box_value = $_[1];
    my $check_value = $_[2];

    my $final_return = "OK";

    my $check_return_checkbox = $self->check_transport_template_checkbox( $template, 'bsfLve', $check_box_value );

    my $check_return_val = $self->check_transport_template_value( $template, 'sF_lve', $check_value );

    if( $check_return_checkbox eq "Not OK" || $check_return_val eq "Not OK" ){
        $final_return = "Not OK"
    }

    return $final_return;
}
# }}}
# {{{ edit_tat_flow_pat_igmp_zap
sub edit_tat_flow_pat_igmp_zap {

    my $self = shift;

    $self->run_alarm_template_checkbox_and_val( 'transport', 'bsfZap', 'sF_zap', $_[0], $_[1], $_[2] );
}
# }}}
# {{{ edit_tat_flow_pat_igmp_zap_check
sub edit_tat_flow_pat_igmp_zap_check {

    my $self = shift;

    my $template = $_[0];
    my $check_box_value = $_[1];
    my $check_value = $_[2];

    my $final_return = "OK";

    my $check_return_checkbox = $self->check_transport_template_checkbox( $template, 'bsfZap', $check_box_value );

    my $check_return_val = $self->check_transport_template_value( $template, 'sF_zap', $check_value );

    if( $check_return_checkbox eq "Not OK" || $check_return_val eq "Not OK" ){
        $final_return = "Not OK"
    }

    return $final_return;
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
# Video Flow Alias
# {{{ video_flow_alias_add
sub video_flow_alias_add {

    my $self = shift;

    my $videoAlias_list= $_[0];
    my $cb1_= $_[1];
    my $alias_submit= $_[2];
    my $videoAlias_name= $_[3]; # Name of Video Flow
    my $videoAlias_destipstatus= $_[4]; # Check box for dest IP
    my $videoAlias_destip= $_[5]; # dest IP value
    my $videoAlias_destmask= $_[6]; # dest mask value
    my $videoAlias_destportstatus= $_[7]; # dest port check box
    my $videoAlias_destport= $_[8]; # dest port value
    my $videoAlias_srcipstatus= $_[9]; # 
    my $videoAlias_sourceip= $_[10]; # source IP value
    my $videoAlias_sourcemask= $_[11]; # source IP mask value
    my $videoAlias_srcportstatus = $_[12]; # source port check box
    my $videoAlias_sourceport= $_[13]; # source port value
    my $videoAlias_vlanstatus = $_[14]; # VLAN ID check box 
    my $videoAlias_vlanid= $_[15]; # VLAN ID Value
    my $videoAlias_ssrcstatus = $_[16]; # SSRC Checkbox
    my $videoAlias_ssrc= $_[17]; # SSRC Value
    my $videoAlias_port= $_[18]; # physical ports used radio button; 0=both ports, 1=port 1 only, 2=port 2 only
    my $videoAlias_multicast= $_[19]; # Add to multicast checkbox
    my $videoAlias_macstatus = $_[20]; # MAC address check box
    my $videoAlias_mac= $_[21]; # MAC address: 00%3A00%3A00%3A00%3A00%3A00
    my $video_videotype= $_[22]; # Vide stream type
    my $videoTs_list= $_[23]; # Transport alarm template; In name format
    my $programFault_list= $_[24]; # Program alarm template; In name format
    my $intendedType= $_[25]; # Intended type
    my $intendedBitrate= $_[26]; # Inteded bitrate
    my $igmp1Sub = $_[27];
    my $igmp2Sub = $_[28];
    my $igmp3Sub = $_[29];
    my $igmp4Sub = $_[30];
    my $igmp5Sub = $_[31];
    my $igmp6Sub = $_[32];
    my $igmp7Sub = $_[33];
    my $igmp8Sub = $_[34];
    my $igmp9Sub = $_[35];
    my $igmp10Sub = $_[36];
    my $igmp11Sub = $_[37];
    my $igmp12Sub = $_[38];
    my $igmp13Sub = $_[39];
    my $igmp14Sub = $_[40];
    my $igmp15Sub = $_[41];

    my $programFault_list = $self->get_programFault_list_number( $programFault_list );
    my $videoTs_list = $self->get_videoTs_list_number( $videoTs_list );

    my $url_string = '/prot/videoalias.html?videoAlias_list='.$videoAlias_list.'&cb1_=None&alias_submit=Add%2FUpdate&videoAlias_name='.$videoAlias_name.'&videoAlias_destipstatus='.$videoAlias_destipstatus.'&videoAlias_destip='.$videoAlias_destip.'&videoAlias_destmask='.$videoAlias_destmask.'&videoAlias_destportstatus='.$videoAlias_destportstatus.'&videoAlias_destport='.$videoAlias_destport.'&videoAlias_srcipstatus='.$videoAlias_srcipstatus.'&videoAlias_sourceip='.$videoAlias_sourceip.'&videoAlias_sourcemask='.$videoAlias_sourcemask.'&videoAlias_sourceport='.$videoAlias_sourceport.'&videoAlias_vlanstatus='.$videoAlias_vlanstatus.'&videoAlias_vlanid='.$videoAlias_vlanid.'&videoAlias_ssrcstatus='.$videoAlias_ssrcstatus.'&videoAlias_ssrc='.$videoAlias_ssrc.'&videoAlias_port='.$videoAlias_port.'&videoAlias_multicast='.$videoAlias_multicast.'&videoAlias_mac='.$videoAlias_mac.'&video_videotype='.$video_videotype.'&videoTs_list='.$videoTs_list.'&programFault_list='.$programFault_list.'&intendedType='.$intendedType.'&intendedBitrate='.$intendedBitrate.'&igmp1Sub='.$igmp1Sub.'&igmp2Sub='.$igmp2Sub.'&igmp3Sub='.$igmp3Sub.'&igmp4Sub='.$igmp4Sub.'&igmp5Sub='.$igmp5Sub.'&igmp6Sub='.$igmp6Sub.'&igmp7Sub='.$igmp7Sub.'&igmp8Sub='.$igmp8Sub.'&igmp9Sub='.$igmp9Sub.'&igmp10Sub='.$igmp10Sub.'&igmp11Sub='.$igmp11Sub.'&igmp12Sub='.$igmp12Sub.'&igmp13Sub='.$igmp13Sub.'&igmp14Sub='.$igmp14Sub.'&igmp15Sub='.$igmp15Sub;

#print $url_string . "\n";
    $self->{mech}->get( "http://".$self->{PAGE_IP}.$url_string );
}

# }}}
# Video Program Alias
# {{{ video_program_alias_add
sub video_program_alias_add{

    my $self = shift;

    my $videoChan_list = $_[0]; # Flow Alias Name
    my $cb1_ = $_[1]; # 
    my $videochan_confirm_ = $_[2]; # Add update var
    my $videoChan_progname = $_[3]; # Program Name
    my $videoName_list = $_[4]; # Flow Alias Name.  Transport Flow this program is in
    my $videoChan_program = $_[5]; # PID #, Program Number
    my $videoChan_prognumber = $_[6]; # STB Channel Number
    my $videoChan_device = $_[7]; # Device Reference Name
    my $videoChan_boffair = $_[8]; # Off air period checkbox
    my $videoChan_offstart = $_[9]; # off air start time: default: 00%3A00
    my $videoChan_offend = $_[10]; # off air end time: default: 00%3A00
    my $programFault_list = $_[11]; # Program template
    my $programOffFault_list = $_[12]; # Program offair tempalte
    my $videoChan_MediaType = $_[13]; # Non-Media Control Program

    my $url_string = '/prot/videochan.html?videoChan_list=0&cb1_='.$cb1_.'&videochan_confirm_=Add%2FUpdate&videoChan_progname='.$videoChan_progname.'&videoName_list='.$videoName_list.'&videoChan_program='.$videoChan_program.'&videoChan_prognumber='.$videoChan_prognumber.'&videoChan_device='.$videoChan_device.'&videoChan_boffair='.$videoChan_boffair.'&videoChan_offstart='.$videoChan_offstart.'&videoChan_offend='.$videoChan_offend.'&programFault_list='.$programFault_list.'&programOffFault_list='.$programOffFault_list.'&videoChan_MediaType='.$videoChan_MediaType;

print $url_string . "\n";
    $self->{mech}->get( "http://".$self->{PAGE_IP}.$url_string );
}
# }}}
#
# Frame Grabber
#
# {{{ fg_remote_press_ok_button
sub fg_remote_press_ok_button{
	
	my $self = shift;
	
	my $url_string = '/dynamic/progguidechansel.html?dirId=5';
	
	$self->{mech}->get( "http://".$self->{PAGE_IP}.$url_string );

	return "OK";
}
# }}}
# {{{ fg_remote_press_pwr_button
sub fg_remote_press_pwr_button{
	
	my $self = shift;
	
	my $url_string = '/dynamic/progguidechansel.html?miscKeyId=P';
	
	$self->{mech}->get( "http://".$self->{PAGE_IP}.$url_string );

	return "OK";
}
# }}}
#
## Internal Functions
#
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

        # This is the number that the template actually refers to
        my $videoTs_list_number = $self->get_videoTs_list_number( $template );

        $url_string = '/prot/videoalarm.html?videoTs_list='.$videoTs_list_number.'&videochar_submit=Add%2FUpdate&videoTs_name='.$template.'&'.$checkbox_name.'='.$enable_disable.'&'.$inputfield_name.'='.$new_val;
    }
    if( $type =~ /program/ ){

        my $programFault_list_number = $self->get_programFault_list_number( $template );

        $url_string = '/prot/videoprogramfault.html?programFault_list='.$programFault_list_number.'&programFault_submit=Add%2FUpdate&programFault_template='.$template.'&'.$checkbox_name.'='.$enable_disable.'&'.$inputfield_name.'='.$new_val;
    }

    $self->{mech}->get( "http://".$self->{PAGE_IP}.$url_string );
#print "http://".$self->{PAGE_IP}.$url_string . "\n";
}
# }}}
    ## Program Alarm Functions
# {{{ get_programFault_list_number
sub get_programFault_list_number {
# In the Program Alarm template page to pull up the correct alarm template, the page uses
# programFault_list variable in the templates name drop down menu to map a number to 
# a templates name.  You need this number to pull up the correct information for a 
# template of your choice.

    my $self = shift;

    my $template_name = $_[0];

    my $programFault_list_number = -1;

    # Pull template page and then get the programFault_list variable that
    # is associated to this template's name
    my $url_string = '/prot/videoprogramfault.html';

    $self->{mech}->get( "http://".$self->{PAGE_IP}.$url_string );

    my $page_content = $self->{mech}->content;

    # Find the select drop down and get the value of the template name
    $page_content =~ /value="(\d+)"(\s?|\s+selected="selected")>$template_name<\/option>/g;

#    print "page_content: " . $1 . "\n";

    $programFault_list_number = $1;

    return $programFault_list_number;

}
# }}}
# {{{ get_template_value
sub get_program_template_value {
# This gets a value from a template given the values html name attribute.
# It also assumes the format for the var is like
# <input name="progF_mlr" value="9"

    my $self = shift;

    my $programFault_list_number = $_[0];
    my $var_to_look_for = $_[1];

    my $return_var = -1;

    my $url_string = '/prot/videoprogramfault.html?programFault_list='.$programFault_list_number;

    $self->{mech}->get( "http://".$self->{PAGE_IP}.$url_string );

    my $page_content = $self->{mech}->content;

    $page_content =~ /name="$var_to_look_for"\s+value="(\d+)"/g;

    $return_var = $1;

    return $return_var;
}
# }}}
#{{{ check_program_template_value
sub check_program_template_value{

    my $self = shift;

    my $template_name = $_[0];
    my $html_var_name = $_[1]; # Var in the html of the program template
    my $check_value = $_[2]; # Value to confirm it is

    my $check_return = "Not OK";

    # Get the templates number mapping to name
    my $programFault_list_num = $self->get_programFault_list_number( $template_name );

    # Then pull up the page with the correct programFault_list number
    # in the URL. With that content varify that the setting in the field
    # is as expected.
    my $expected_value = $self->get_program_template_value( $programFault_list_num, $html_var_name );
# print "html_var_name: " . $html_var_name . "\n";
# print $expected_value . " - " . $check_value . "\n";
    if( $expected_value == $check_value ){
        $check_return = "OK";
    }
# print $check_return . "\n";
    return $check_return;

}
# }}}
# {{{ check_program_template_checkbox
sub check_program_template_checkbox {
# Check if the check box for the given param is the same as the one
# passed in.

    my $self = shift;

    my $template_name = $_[0];
    my $html_var_name = $_[1]; # Var in the html of the program template
    my $is_checked = $_[2]; # Value to confirm it is

    my $check_return = "Not OK";

    # Get the templates number mapping to name
    my $programFault_list_num = $self->get_programFault_list_number( $template_name );

    # Get the page
    my $url_string = '/prot/videoprogramfault.html?programFault_list='.$programFault_list_num;

    $self->{mech}->get( "http://".$self->{PAGE_IP}.$url_string );

    my $page_content = $self->{mech}->content;
#print $page_content;
#print "html_var_name: " . $html_var_name . "\n";
    # Find the checkbox <input> line and grab the checked="checked" is there or not
    #$page_content =~ /name="$html_var_name"\s+value="1"(\s+|CHECKED)/g; 
    $page_content =~ /name="$html_var_name"   value="1" (\s+|CHECKED)/g;

    my $search_var = $1;
#print "search_var: " . $search_var . "\n";
    if( $search_var eq 'CHECKED' ){
        if( $is_checked == '1' ){
            $check_return = "OK";
        }
    } elsif( $search_var =~ /\s+/ ){
        if( $is_checked == '0' || $is_checked == '-1' ){
            $check_return = "OK"
        }
    }
#print "Check return for checkbox: " . $check_return . "\n";
    return $check_return;
}
# }}}
# {{{ check_program_template_selectbox
sub check_program_template_selectbox{

    my $self = shift;

    my $template_name = $_[0];
    my $html_var_name = $_[1]; # Var in the html of the program template
    my $check_value = $_[2]; # Value to confirm it is

    my $check_return = "Not OK";

    # Get the templates number mapping to name
    my $programFault_list_num = $self->get_programFault_list_number( $template_name );

    # Get the page
    my $url_string = '/prot/videoprogramfault.html?programFault_list='.$programFault_list_num;

    $self->{mech}->get( "http://".$self->{PAGE_IP}.$url_string );

    my $page_content = $self->{mech}->content;

    # Flatten html.  Take out all the line returns
    $page_content =~ s/\n//g;

    # Check if selct list is slected
    if( $page_content =~ /><select name="progF_control" size="1">.*(value="$check_value"\sSELECTED).*<\/select>/g ){

#print $1 . "--------" . $2;

        $check_return = "OK";
    }

    return $check_return;
}
# }}}
    ## Transport Alarm Functions
# {{{ get_videoTs_list_number
sub get_videoTs_list_number {
# In the Transport Alarm template page to pull up the correct alarm template, the page uses
# videoTs_list variable in the templates name drop down menu to map a number to
# a templates name.  You need this number to pull up the correct information for a
# template of your choice.

    my $self = shift;

    my $template_name = $_[0];

    my $videoTs_list_number = -1;

    # Pull template page and then get the videoTs_list variable that
    # is associated to this template's name
    my $url_string = '/prot/videoalarm.html';

    $self->{mech}->get( "http://".$self->{PAGE_IP}.$url_string );

    my $page_content = $self->{mech}->content;

    # Find the select drop down and get the value of the template name
    $page_content =~ /value="(\d+)"(\s?|\s+selected="selected")>$template_name<\/option>/g;

#    print "page_content: " . $1 . "\n";

    $videoTs_list_number = $1;

    return $videoTs_list_number;

}
# }}}
# {{{ get_transport_template_value
sub get_transport_template_value {
# This gets a value from a template given the values html name attribute.
# It also assumes the format for the var is like
# <input name="progF_mlr" value="9"

    my $self = shift;

    my $video_list_number = $_[0];
    my $var_to_look_for = $_[1];

    my $return_var = -1;

    my $url_string = '/prot/videoalarm.html?videoTs_list='.$video_list_number;

    $self->{mech}->get( "http://".$self->{PAGE_IP}.$url_string );

    my $page_content = $self->{mech}->content;

    $page_content =~ /name="$var_to_look_for"\s+value="(\d+)"/g;

    $return_var = $1;

    return $return_var;
}
# }}}
# {{{ check_transport_template_value
sub check_transport_template_value{

    my $self = shift;

    my $template_name = $_[0];
    my $html_var_name = $_[1]; # Var in the html of the program template
    my $check_value = $_[2]; # Value to confirm it is

    my $check_return = "Not OK";

    # Get the templates number mapping to name
    my $programFault_list_num = $self->get_videoTs_list_number( $template_name );

    # Then pull up the page with the correct programFault_list number
    # in the URL. With that content verify that the setting in the field
    # is as expected.
    my $expected_value = $self->get_transport_template_value( $programFault_list_num, $html_var_name );
# print "html_var_name: " . $html_var_name . "\n";
# print $expected_value . " - " . $check_value . "\n";
    if( $expected_value == $check_value ){
        $check_return = "OK";
    }
# print $check_return . "\n";
    return $check_return;

}
# }}}
# {{{ check_transport_template_checkbox
sub check_transport_template_checkbox {
# Check if the check box for the given param is the same as the one
# passed in.

    my $self = shift;

    my $template_name = $_[0];
    my $html_var_name = $_[1]; # Var in the html of the program template
    my $is_checked = $_[2]; # Value to confirm it is

    my $check_return = "Not OK";

    # Get the templates number mapping to name
    my $video_list_num = $self->get_videoTs_list_number( $template_name );

    # Get the page
    my $url_string = '/prot/videoalarm.html?videoTs_list='.$video_list_num;
#print "url_string: " . $url_string . "\n";
    $self->{mech}->get( "http://".$self->{PAGE_IP}.$url_string );

    my $page_content = $self->{mech}->content;
#print $page_content;
#print "html_var_name: " . $html_var_name . "\n";
    # Find the checkbox <input> line and grab the checked="checked" is there or not
    $page_content =~ /name="$html_var_name"\s+value="1" (\s+|CHECKED)/g;

    my $search_var = $1;
#print "search_var: " . $search_var . "\n";
    if( $search_var eq 'CHECKED' ){
        if( $is_checked == '1' ){
            $check_return = "OK";
        }
    } elsif( $search_var =~ /\s+/ ){
        if( $is_checked == '0' || $is_checked == '-1' ){
            $check_return = "OK"
        }
    }
#print "Check return for checkbox: " . $check_return . "\n";
    return $check_return;
}
# }}}
# {{{ check_transport_template_selectbox
sub check_transport_template_selectbox{

    my $self = shift;

    my $template_name = $_[0];
    my $html_var_name = $_[1]; # Var in the html of the program template
    my $check_value = $_[2]; # Value to confirm it is

    my $check_return = "Not OK";

    # Get the templates number mapping to name
    my $video_list_num = $self->get_programFault_list_number( $template_name );

    # Get the page
    my $url_string = '/prot/videoalarm.html?videoTs_list='.$video_list_num;

    $self->{mech}->get( "http://".$self->{PAGE_IP}.$url_string );

    my $page_content = $self->{mech}->content;

    # Flatten html.  Take out all the line returns
    $page_content =~ s/\n//g;

    # Check if selct list is slected
    if( $page_content =~ /><select name="progF_control" size="1">.*(value="$check_value"\sSELECTED).*<\/select>/g ){

#print $1 . "--------" . $2;

        $check_return = "OK";
    }

    return $check_return;
}
# }}}
    ## Video Flow Alias
# {{{ get_video_flow_alias_list_number
sub get_video_flow_alias_list_number {
# In the Video Flow Alias has a drop down on the top to list all the
# flows created.  To pull up the information about a particular flow
# you need the number associated with the select drop down box.
# This function will get that number given a Video Flow Alias name.

    my $self = shift;

    my $template_name = $_[0];

    my $list_number = -1;

    # Pull template page and then get the programFault_list variable that
    # is associated to this template's name
    my $url_string = '/dynamic/aliasList.html';

    $self->{mech}->get( "http://".$self->{PAGE_IP}.$url_string );

    my $page_content = $self->{mech}->content;

    # Find the select drop down and get the value of the template name
    #$page_content =~ /value="(\d+)"(\s?|\s+selected="selected")>$template_name<\/option>/g;
    $page_content =~ /<p>(\d{8}) $template_name<\/p>/g;

#    print "page_content: " . $1 . "\n";

    $list_number = $1;

    return $list_number;

}
# }}}
    ## Video Program Alias
# {{{ get_video_program_alias_list_number
sub get_video_program_alias_list_number {
# In the Video Flow Alias has a drop down on the top to list all the
# flows created.  To pull up the information about a particular flow
# you need the number associated with the select drop down box.
# This function will get that number given a Video Flow Alias name.

    my $self = shift;

    my $template_name = $_[0];

    my $list_number = -1;

    # Pull template page and then get the programFault_list variable that
    # is associated to this template's name
    my $url_string = '/dynamic/prgAliasList.html';

    $self->{mech}->get( "http://".$self->{PAGE_IP}.$url_string );

    my $page_content = $self->{mech}->content;

    # Find the select drop down and get the value of the template name
    #$page_content =~ /value="(\d+)"(\s?|\s+selected="selected")>$template_name<\/option>/g;
    $page_content =~ /<p>(\d{4})\d+ $template_name/g;

#    print "page_content: " . $1 . "\n";

    $list_number = $1;

    return $list_number;

}
# }}}
    ## Generic get values
# {{{ get_page_mapping
sub get_page_mapping{
# This function returns a url for a given name for a page
# Just to make it easier to reference a page
# The $template var only applies to pages with different templates

    my $self = shift;

    my $page = $_[0];
    my $template = $_[1]; # A number coressponding to a template

    my $url_string = '/none';

    if( $page eq 'transport_alarm' ){ $url_string = '/prot/videoalarm.html?videoTs_list='.$template; }
    elsif( $page eq 'program_alarm' ){ $url_string = '/prot/videoprogramfault.html?programFault_list='.$template; }
    elsif( $page eq 'video_flow_alias' ){ $url_string = '/prot/videoalias.html?videoAlias_list='.$template; }
    elsif( $page eq 'video_program_alias' ){ $url_string = '/prot/videochan.html?videoChan_list='.$template; }
    elsif( $page eq 'management_port' ){ $url_string = '/config/sysconfig.html'; }

    return $url_string;
}
# }}}
# {{{ get_select_dropdown_value
sub get_select_dropdown_value {
# As a generic function this gets a value associated to a select dropdown
# <option value="2"> Ignore All PIDS </option>
#
# Also
# Each area that has a template associated with it has a drop down menu list.
# The drop down menu is associated to a value to pass into the get string to get
# the correct template.  This function goes to the main page of the area where
# the drop down list is and pulls the value for the template and returns it.
# It is doing it in a generic way.  It searches for a select drop down tag with
# the template name passed in and returns the value associated with that.  If
# the page has 2 select drop down list with the same name, that could be a problem

    my $self = shift;

    my $page = $_[0]; # This is the page name where the template is
    my $template_number = $_[1]; # Has to be a numeric value, only applies to pages with templates
    my $dropdown_name = $_[2];

    my $list_number = -1;
    my $url_string = $self->get_page_mapping( $page, $template_number );

    $self->{mech}->get( "http://".$self->{PAGE_IP}.$url_string );

    my $page_content = $self->{mech}->content;

    # Find the select drop down and get the value of the template name
    $page_content =~ /value="(\d+)"(\s?|\s+selected="selected")>$dropdown_name<\/option>/g;

#    print "page_content: " . $1 . "\n";

    $list_number = $1;

    return $list_number;
}
# }}}
# {{{ get_text_input_value
sub get_text_input_value{
# This gets a value from a page given the values html name attribute.
# It also assumes the format for the var is like
# <input name="progF_mlr" value="9"

    my $self = shift;

    my $page = $_[0];
    my $template_number = $_[1]; # Has to be a numeric value,  only applies to pages with templates
    my $var_to_look_for = $_[2]; # html var

    my $return_var = -1;

    my $url_string = $self->get_page_mapping( $page, $template_number );

    $self->{mech}->get( "http://".$self->{PAGE_IP}.$url_string );

    my $page_content = $self->{mech}->content;

    $page_content =~ /name="$var_to_look_for"\s+value="(\d+|\w+|\d+\.\d+\.\d+\.\d+)"/g;

    $return_var = $1;

    return $return_var;

}
# }}}
# {{{ get_checkbox_value
sub get_checkbox_value{
# Check if the check box for the given param is the same as the one
# passed in.

    my $self = shift;

    my $page = $_[0];
    my $template_number = $_[1]; # Has to be a numeric value
    my $var_to_look_for = $_[2]; # html var

    my $check_return = '0';

    # Get the page
    my $url_string = $self->get_page_mapping( $page, $template_number );

    $self->{mech}->get( "http://".$self->{PAGE_IP}.$url_string );

    my $page_content = $self->{mech}->content;

    # Find the checkbox <input> line and grab the checked="checked" is there or not
    $page_content =~ /name="$var_to_look_for"\s+value="1" (\s+|CHECKED)/g;

    my $search_var = $1;

    if( $search_var eq 'CHECKED' ){
    $check_return = "1";
    }
 
    return $check_return;
}
# }}}
#
# QA Check Functions
#
# {{{ test_runner
sub test_runner {
# The test_runner is here to run the QA tests.  It takes in a bunch
# of params and runs the test based on the params.
#
# usage: $iq->test_runner( $test_to_run, $probe_type, $args );
# $test_to_run - can be any function in this class
# $probe_type - is defined on top of this class
# $args - is a | delmited format: 'ip|Admin User|Admin password|etc if needed'
#
    my $self = shift;

    my $test_to_run = $_[0];
    my $probe_type = $_[1];
    my $args = $_[2];

    my @vars = split( /\|/, $args );

    my $probe_ip = $vars[0];
    my $admin_user = $vars[1];
    my $admin_pass = $vars[2];
    my $additional_vars = $vars[3];

    $self->set_probe_type( $probe_type );
    $self->set_page_ip( $probe_ip );

    $self->start_mech();

    $self->login( $admin_user, $admin_pass );

    my $test_output = $self->$test_to_run( $additional_vars );

    return $test_output;
}
# }}}
# Top Level Pages
# {{{ check_main_menu
sub check_main_menu {

    my $self = shift;

    my $url_string = '/status/main_menu.html';

    my $returnValue = 'Not OK';

    $self->{mech}->get("http://".$self->{PAGE_IP}.$url_string);

    my $page_content = $self->{mech}->content();

    # Checking Page
    if( $page_content =~ /Logout/g && $page_content =~ /System Status/g ){
        $returnValue = 'OK';
    }

    return $returnValue;
}
# }}}
# {{{ check_status_page
sub check_status_page {

    my $self = shift;

    # This page holds the frame and ajax call for the html body
    my $url_string = '/status/sysstatus.html';

    my $returnValue = 'Not OK: 1';

    $self->{mech}->get("http://".$self->{PAGE_IP}.$url_string);

    my $page_content = $self->{mech}->content();

    # Checking Page
    if( $page_content =~ /SYSTEM STATUS/g && $page_content =~ /sysstatus\.html/g ){
        $returnValue = 'OK';
    }

    # This page holds the body with the information about system status
    $url_string = '/dynamic/sysstatus.html';

    if( $returnValue eq 'OK' ){

        $returnValue = 'Not OK: 2';

        $self->{mech}->get("http://".$self->{PAGE_IP}.$url_string);

        $page_content = $self->{mech}->content();

        # Checking Page
        if( $page_content =~ /Firmware/g && $page_content =~ /System/g ){
            $returnValue = 'OK';
        }
    }

    return $returnValue;
}
# }}}
# Network Statistic Pages
# {{{ check_network_statistic_RMON
sub check_network_statistic_RMON {

    my $self = shift;

    # This page holds the frame and ajax call for the html body
    my $url_string = '/status/rmon.html';

    my $returnValue = 'Not OK: 1';

    $self->{mech}->get("http://".$self->{PAGE_IP}.$url_string);

    my $page_content = $self->{mech}->content();

    # Checking Page
    if( $page_content =~ /RMON/g && $page_content =~ /rmonstats\.html/g ){
        $returnValue = 'OK';
    }

    # This page holds the body with the information about system status
    $url_string = '/dynamic/rmonstats.html';

    if( $returnValue eq 'OK' ){
        $returnValue = 'Not OK: 2';

        $self->{mech}->get("http://".$self->{PAGE_IP}.$url_string);

        $page_content = $self->{mech}->content();

        # Checking Page
        if( $page_content =~ /<text>/g && $page_content =~ /<a1>(\d|,)+<\/a1>/g ){
            $returnValue = 'OK';
        }
    }

    return $returnValue;

}
# }}}
# {{{ check_network_statistic_IP_TOS
sub check_network_statistic_IP_TOS {

    my $self = shift;

    my $url_string = '/dynamic/tosstats.htm';

    my $returnValue = 'Not OK: 1';

    $self->{mech}->get("http://".$self->{PAGE_IP}.$url_string);

    my $page_content = $self->{mech}->content();

    # Checking Page
    if( $page_content =~ /IP TOS Statistics/g && $page_content =~ /Class 0/g ){
        $returnValue = 'OK';
    }

    return $returnValue;
}
# }}}
# {{{ check_network_statistic_media_overview
sub check_network_statistic_media_overview {

    my $self = shift;

    # This page holds the frame and ajax call for the html body
    my $url_string = '/status/mediaview.html';

    my $returnValue = 'Not OK: 1';

    $self->{mech}->get("http://".$self->{PAGE_IP}.$url_string);

    my $page_content = $self->{mech}->content();

    # Checking Page
    if( $page_content =~ /Media Overview/g && $page_content =~ /mediaview\.html/g ){
        $returnValue = 'OK';
    }

    # This page holds the body with the information about system status
    $url_string = '/dynamic/mediaview.html';

    if( $returnValue eq 'OK' ){
        $returnValue = 'Not OK: 2';

        $self->{mech}->get("http://".$self->{PAGE_IP}.$url_string);

        $page_content = $self->{mech}->content();

        # Checking Page
        if( $page_content =~ /a/g && $page_content =~ /<text>/g ){
            $returnValue = 'OK';
        }
    }

    return $returnValue;
}
# }}}
# {{{ check_network_statistic_flow_census
sub check_network_statistic_flow_census {

    my $self = shift;

    # This page holds the frame and ajax call for the html body
    my $url_string = '/status/census.html';

    my $returnValue = 'Not OK: 1';

    $self->{mech}->get("http://".$self->{PAGE_IP}.$url_string);

    my $page_content = $self->{mech}->content();

    # Checking Page
    if( $page_content =~ /FLOW CENSUS/g && $page_content =~ /flowcensus\.html/g ){
        $returnValue = 'OK';
    }

    # This page holds the body with the information about system status
    $url_string = '/dynamic/flowcensus.html';

    if( $returnValue eq 'OK' ){
        $returnValue = 'Not OK: 2';

        $self->{mech}->get("http://".$self->{PAGE_IP}.$url_string);

        $page_content = $self->{mech}->content();

        # Checking Page
        if( $page_content =~ /tbody/g && $page_content =~ /table/g ){
            $returnValue = 'OK';
        }
    }

    return $returnValue;
}
# }}}
# {{{ check_network_statistic_program_view
sub check_network_statistic_program_view {

    my $self = shift;

    # This page holds the frame and ajax call for the html body
    my $url_string = '/prot/programs.html';

    my $returnValue = 'Not OK: 1';

    $self->{mech}->get("http://".$self->{PAGE_IP}.$url_string);

    my $page_content = $self->{mech}->content();

    # Checking Page
    if( $page_content =~ /PROGRAM VIEW/g && $page_content =~ /censuscombo\.html/g ){
        $returnValue = 'OK';
    }

    # This page holds the body with the information about system status
    $url_string = '/dynamic/censuscombo.html';

    if( $returnValue eq 'OK' ){
        $returnValue = 'Not OK: 2';

        $self->{mech}->get("http://".$self->{PAGE_IP}.$url_string);

        $page_content = $self->{mech}->content();

        # Checking Page
        if( $page_content =~ /xml/g && $page_content =~ /standalone/g ){
            $returnValue = 'OK';
        }

        # This page holds the body with the information about system status
        $url_string = '/dynamic/pgmdetails.html';

        if( $returnValue eq 'OK' ){
            $returnValue = 'Not OK: 3';

            $self->{mech}->get("http://".$self->{PAGE_IP}.$url_string);

            $page_content = $self->{mech}->content();

            # Checking Page
            if( $page_content =~ /xml/g && $page_content =~ /standalone/g ){
                $returnValue = 'OK';
            }
        }
    }
    return $returnValue;
}
# }}}
# {{{ check_network_statistic_flow_status
sub check_network_statistic_flow_status {

    my $self = shift;

    # This page holds the frame and ajax call for the html body
    my $url_string = '/status/flowstatus.html';

    my $returnValue = 'Not OK: 1';

    $self->{mech}->get("http://".$self->{PAGE_IP}.$url_string);

    my $page_content = $self->{mech}->content();

    # Checking Page
    if( $page_content =~ /FLOW STATUS/g && $page_content =~ /pmstats\.html/g ){
        $returnValue = 'OK';
    }

    # This page holds the body with the information about system status
    $url_string = '/dynamic/pmstats.html';

    if( $returnValue eq 'OK' ){

        $returnValue = 'Not OK: 2';

        $self->{mech}->get("http://".$self->{PAGE_IP}.$url_string);

        $page_content = $self->{mech}->content();

# Checking Page
        if( $page_content =~ /table/g && $page_content =~ /tbody/g ){
            $returnValue = 'OK';
        }

# This page holds the body with the information about system status
        $url_string = '/dynamic/streamstats.html';

        if( $returnValue eq 'OK' ){

            $returnValue = 'Not OK: 3';

            $self->{mech}->get("http://".$self->{PAGE_IP}.$url_string);

            $page_content = $self->{mech}->content();

# Checking Page
            if( $page_content =~ /xml/g && $page_content =~ /div/g ){
                $returnValue = 'OK';
            }
        }
    }

    return $returnValue;
}
# }}}
# Video Program Alarm Template's Settings
# {{{ set_and_check_all_program_alarm_template
sub set_and_check_all_program_alarm_template{ 

    my $self = shift;

    my $programFault_list='0';
    my $programFault_submit='Add%2FUpdate';
    my $programFault_template='new-1';
    my $progF_mlr='99';
    my $bpfMLp='1';
    my $progF_Lp='88';
    my $bpfMLd='1';
    my $progF_Ld='72';
    my $bpfMLoss15='1';
    my $progF_ccloss='66';
    my $bpfMLoss='1';
    my $progF_loss24='55';
    my $bpfMls24='1';
    my $progF_mls24='44';
    my $bpfMls15='1';
    my $progF_mls15='33';
    my $progF_control='1';
    my $progF_bscramble='1';
    my $progF_scramble='1';
    my $progF_outsoak='21';
    my $progF_soak='22';
    my $progF_iAudio='1';
    my $progF_pidtype1='1';
    my $progF_pid1='23';
    my $progF_pidtype2='1';
    my $progF_pid2='26';
    my $progF_pidtype3='1';
    my $progF_pid3='29';
    my $progF_pidtype1Act='1';
    my $progF_pid1Text='23';
    my $progF_pid1Sel='8';
    my $progF_bPid1='1';
    my $progF_thr1='24';
    my $progF_bmPid1='1';
    my $progF_mthr1='25';
    my $progF_pidtype2Act='1';
    my $progF_pid2Text='26';
    my $progF_pid2Sel='8';
    my $progF_bPid2='1';
    my $progF_thr2='27';
    my $progF_bmPid2='1';
    my $progF_mthr2='28';
    my $progF_pidtype3Act='1';
    my $progF_pid3Text='29';
    my $progF_pid3Sel='8';
    my $progF_bPid3='1';
    my $progF_thr3='30';
    my $progF_bmPid3='1';
    my $progF_mthr3='31';
    my $progF_Ovideo='1';
    my $progF_ovidpid='1504';
    my $progF_video='1';
    my $progF_vidpid='100000';
    my $progF_mvideo='1';
    my $progF_mvidpid='250000';
    my $progF_OAudio='1';
    my $progF_oaudpid='1504';
    my $progF_audio='1';
    my $progF_audpid='25000';
    my $progF_maudio='1';
    my $progF_maudpid='250000';
    my $progF_pmt='1';
    my $progF_pcr='1'; 

    $self->program_alarm_template_add( $programFault_list, $programFault_submit , $programFault_template , $progF_mlr , $bpfMLp , $progF_Lp , $bpfMLd , $progF_Ld , $bpfMLoss15 , $progF_ccloss, $bpfMLoss, $progF_loss24, $bpfMls24, $progF_mls24, $bpfMls15, $progF_mls15, $progF_control, $progF_bscramble, $progF_scramble, $progF_outsoak, $progF_soak, $progF_iAudio, $progF_pidtype1, $progF_pid1, $progF_pidtype2, $progF_pid2, $progF_pidtype3, $progF_pid3, $progF_pidtype1Act, $progF_pid1Text, $progF_pid1Sel, $progF_bPid1, $progF_thr1, $progF_bmPid1, $progF_mthr1, $progF_pidtype2Act, $progF_pid2Text, $progF_pid2Sel, $progF_bPid2, $progF_thr2, $progF_bmPid2, $progF_mthr2, $progF_pidtype3Act, $progF_pid3Text, $progF_pid3Sel, $progF_bPid3, $progF_thr3, $progF_bmPid3, $progF_mthr3, $progF_Ovideo, $progF_ovidpid, $progF_video, $progF_vidpid, $progF_mvideo, $progF_mvidpid, $progF_OAudio, $progF_oaudpid, $progF_audio, $progF_audpid, $progF_maudio, $progF_maudpid, $progF_pmt, $progF_pcr );

    return 'OK';
}
# }}}
# {{{ set_and_check_pat_mdi_mlr
sub set_and_check_pat_mdi_mlr {

    my $self = shift;

    my $template_name = 'qaAutomation1';
    my $mdi_mlr_value = '99';

    my $returnValue = "-1";

    # Set new value
    $self->pat_mdi_mlr_edit( $template_name, $mdi_mlr_value );

    # Check Value
    $returnValue = $self->pat_mdi_mlr_check( $template_name, $mdi_mlr_value );

    return $returnValue;
}
# }}}
# {{{ set_and_check_pat_pmla_mlt15
sub set_and_check_pat_pmla_mlt15 {

    my $self = shift;

    my $template_name = 'qaAutomation1';
    my $enable_disable = '1'; # check the check box
    my $check_box_is_checked = '1';
    my $new_val = '99';

    my $returnValue = "-1";

    # Set new value
    $self->pat_pmla_mlt15( $template_name, $enable_disable, $new_val );

    # Check Value
    $returnValue = $self->pat_pmla_mlt15_check( $template_name, $check_box_is_checked, $new_val );

    return $returnValue;
}
# }}}
# {{{ set_and_check_pat_pmla_mls_lp
sub set_and_check_pat_pmla_mls_lp {

    my $self = shift;

    my $template_name = 'qaAutomation1';
    my $enable_disable = '1'; # check the check box
    my $check_box_is_checked = '1';
    my $new_val = '99';

    my $returnValue = "-1";

    # Set new value
    $self->pat_pmla_mls_lp( $template_name, $enable_disable, $new_val );

    # Check Value
    $returnValue = $self->pat_pmla_mls_lp_check( $template_name, $check_box_is_checked, $new_val );

    return $returnValue;
}
# }}}
# {{{ set_and_check_pat_pmla_mls_ld
sub set_and_check_pat_pmla_mls_ld {

    my $self = shift;

    my $template_name = 'qaAutomation1';
    my $enable_disable = '1'; # check the check box
    my $check_box_is_checked = '1';
    my $new_val = '99';

    my $returnValue = "-1";

    # Set new value
    $self->pat_pmla_mls_ld( $template_name, $enable_disable, $new_val );

    # Check Value
    $returnValue = $self->pat_pmla_mls_ld_check( $template_name, $check_box_is_checked, $new_val );

    return $returnValue;
}
# }}}
# {{{ set_and_check_pat_pmla_mls24
sub set_and_check_pat_pmla_mls24 {

    my $self = shift;

    my $template_name = 'qaAutomation1';
    my $enable_disable = '1'; # check the check box
    my $check_box_is_checked = '1';
    my $new_val = '99';

    my $returnValue = "-1";

    # Set new value
    $self->pat_pmla_mls24( $template_name, $enable_disable, $new_val );

    # Check Value
    $returnValue = $self->pat_pmla_mls24_check( $template_name, $check_box_is_checked, $new_val );

    return $returnValue;
}
# }}}
# {{{ set_and_check_pat_pmla_mls15
sub set_and_check_pat_pmla_mls15 {

    my $self = shift;

    my $template_name = 'qaAutomation1';
    my $enable_disable = '0'; # check the check box
    my $check_box_is_checked = '0';
    my $new_val = '99';

    my $returnValue = "-1";

    # Set new value
    $self->pat_pmla_mls15( $template_name, $enable_disable, $new_val );

    # Check Value
    $returnValue = $self->pat_pmla_mls15_check( $template_name, $check_box_is_checked, '9');#$new_val );

    return $returnValue;
}
# }}}
# {{{ set_and_check_edit_pat_pma_program_scramble_state
sub set_and_check_edit_pat_pma_program_scramble_state{

    my $self = shift;

    my $template_name = 'qaAutomation1';
    my $enable_disable = '1'; # check the check box
    my $check_box_is_checked = '1';
    my $new_val = '1';

    my $returnValue = "-1";

    # Set new value
    $self->edit_pat_pma_program_scramble_state( $template_name, $enable_disable, $new_val );

    # Check Value
    $returnValue = $self->edit_pat_pma_program_scramble_state_check( $template_name, $check_box_is_checked, $new_val );

    return $returnValue;
}
# }}}
# {{{ set_and_check_pat_pma_pid_monitor_status
sub set_and_check_pat_pma_pid_monitor_status{

    my $self = shift;

    my $template_name = 'qaAutomation1';
    my $new_val = '2';

    my $returnValue = "-1";

    # Set new value
    $self->edit_pat_pma_pid_monitor_status( $template_name, $new_val );

    # Check Value
    $returnValue = $self->edit_pat_pma_pid_monitor_status_check( $template_name, $new_val );

    return $returnValue;
}
# }}}
# {{{ set_and_check_edit_pat_pma_pid_alarm_trigger_period
sub set_and_check_edit_pat_pma_pid_alarm_trigger_period{

    my $self = shift;

    my $template_name = 'qaAutomation1';
    my $new_val = '99';

    my $returnValue = "-1";

    # Set new value
    $self->edit_pat_pma_pid_alarm_trigger_period( $template_name, $new_val );

    # Check Value
    $returnValue = $self->edit_pat_pma_pid_alarm_trigger_period_check( $template_name, $new_val );

    return $returnValue;
}
# }}}
# {{{ set_and_check_edit_pat_pma_ignore_secondary_audio_pid
sub set_and_check_edit_pat_pma_ignore_secondary_audio_pid{

    my $self = shift;

    my $template_name = 'qaAutomation1';
    my $enable_disable = '1'; # check the check box

    my $returnValue = "-1";

    # Set new value
    $self->edit_pat_pma_ignore_secondary_audio_pid( $template_name, $enable_disable );

    # Check Value
    $returnValue = $self->edit_pat_pma_ignore_secondary_audio_pid_check( $template_name, $enable_disable );

    return $returnValue;
}
# }}}
# {{{ set_and_check_edit_ppbma_video_outage_val
sub set_and_check_edit_ppbma_video_outage_val{

    my $self = shift;

    my $template_name = 'qaAutomation1';
    my $enable_disable = '1'; # check the check box
    my $check_box_is_checked = '1';
    my $new_val = '2';

    my $returnValue = "-1";

    # Set new value
    $self->edit_ppbma_video_outage_val( $template_name, $enable_disable, $new_val );

    # Check Value
    $returnValue = $self->edit_ppbma_video_outage_val_check( $template_name, $check_box_is_checked, $new_val );

    return $returnValue;
}
# }}}
# {{{ set_and_check_edit_ppbma_video_min_val
sub set_and_check_edit_ppbma_video_min_val{

    my $self = shift;

    my $template_name = 'qaAutomation1';
    my $enable_disable = '1'; # check the check box
    my $check_box_is_checked = '1';
    my $new_val = '2';

    my $returnValue = "-1";

    # Set new value
    $self->edit_ppbma_video_min_val( $template_name, $enable_disable, $new_val );

    # Check Value
    $returnValue = $self->edit_ppbma_video_min_val_check( $template_name, $check_box_is_checked, $new_val );

    return $returnValue;
}
# }}}
# {{{ set_and_check_edit_ppbma_video_max_val
sub set_and_check_edit_ppbma_video_max_val{

    my $self = shift;

    my $template_name = 'qaAutomation1';
    my $enable_disable = '1'; # check the check box
    my $check_box_is_checked = '1';
    my $new_val = '2';

    my $returnValue = "-1";

    # Set new value
    $self->edit_ppbma_video_max_val( $template_name, $enable_disable, $new_val );

    # Check Value
    $returnValue = $self->edit_ppbma_video_max_val_check( $template_name, $check_box_is_checked, $new_val );

    return $returnValue;
}
# }}}
# {{{ set_and_check_edit_ppbma_audo_outage_val
sub set_and_check_edit_ppbma_audo_outage_val{

    my $self = shift;

    my $template_name = 'qaAutomation1';
    my $enable_disable = '1'; # check the check box
    my $check_box_is_checked = '1';
    my $new_val = '2';

    my $returnValue = "-1";

    # Set new value
    $self->edit_ppbma_audo_outage_val( $template_name, $enable_disable, $new_val );

    # Check Value
    $returnValue = $self->edit_ppbma_audo_outage_val_check( $template_name, $check_box_is_checked, $new_val );

    return $returnValue;
}
# }}}
# {{{ set_and_check_edit_ppbma_audio_min_val
sub set_and_check_edit_ppbma_audio_min_val{

    my $self = shift;

    my $template_name = 'qaAutomation1';
    my $enable_disable = '1'; # check the check box
    my $check_box_is_checked = '1';
    my $new_val = '2';

    my $returnValue = "-1";

    # Set new value
    $self->edit_ppbma_audio_min_val( $template_name, $enable_disable, $new_val );

    # Check Value
    $returnValue = $self->edit_ppbma_audio_min_val_check( $template_name, $check_box_is_checked, $new_val );

    return $returnValue;
}
# }}}
# {{{ set_and_check_edit_ppbma_audio_max_val
sub set_and_check_edit_ppbma_audio_max_val{

    my $self = shift;

    my $template_name = 'qaAutomation1';
    my $enable_disable = '1'; # check the check box
    my $check_box_is_checked = '1';
    my $new_val = '2';

    my $returnValue = "-1";

    # Set new value
    $self->edit_ppbma_audio_max_val( $template_name, $enable_disable, $new_val );

    # Check Value
    $returnValue = $self->edit_ppbma_audio_max_val_check( $template_name, $check_box_is_checked, $new_val );

    return $returnValue;
}
# }}}
# {{{ set_and_check_edit_ppbma_pmt_pid_outage
sub set_and_check_edit_ppbma_pmt_pid_outage{

    my $self = shift;

    my $template_name = 'qaAutomation1';
    my $enable_disable = '1'; # check the check box
    my $check_box_is_checked = '1';

    my $returnValue = "-1";

    # Set new value
    $self->edit_ppbma_pmt_pid_outage( $template_name, $enable_disable );

    # Check Value
    $returnValue = $self->edit_ppbma_pmt_pid_outage_check( $template_name, $check_box_is_checked );

    return $returnValue;
}
# }}}
# {{{ set_and_check_edit_ppbma_pmt_pcr_pid_outage
sub set_and_check_edit_ppbma_pmt_pcr_pid_outage{

    my $self = shift;

    my $template_name = 'qaAutomation1';
    my $enable_disable = '1'; # check the check box
    my $check_box_is_checked = '1';

    my $returnValue = "-1";

    # Set new value
    $self->edit_ppbma_pmt_pcr_pid_outage( $template_name, $enable_disable );

    # Check Value
    $returnValue = $self->edit_ppbma_pmt_pcr_pid_outage_check( $template_name, $check_box_is_checked );

    return $returnValue;
}
# }}}
# Transport Alarm Templates Settings
# {{{ set_and_check_all_transport_alarm_template
sub set_and_check_all_transport_alarm_template{

    my $self = shift;

    my $videoTs_list='0';
    my $videochar_submit='Add%2FUpdate';
    my $videoTs_name='new-1';
    my $sF_bProgCount='1';
    my $sF_progCount='99';
    my $videoTs_bAlign='1';
    my $bsfRtplp='1';
    my $sF_rtplp='88';
    my $bsfRtpld='1';
    my $sF_rtpld='77';
    my $bsfRtptotloss='1';
    my $sF_rtptotloss='66';
    my $bsfRtploss24='1';
    my $sF_rtploss24='55';
    my $bsfls15='1';
    my $sF_ls15='44';
    my $bsfls24='1';
    my $sF_ls24='33';
    my $bsfMdi='1';
    my $sF_mdi='21.000000';
    my $bsfVb='1';
    my $sF_VB='22';
    my $bsfLve='1';
    my $sF_lve='23';
    my $bsfZap='1';
    my $sF_zap='24';
    my $sF_bitDev='25';
    my $bsfMaxBit='1';
    my $bsfmaxbps='1';
    my $sF_maxbps='26';
    my $bsfminbps='1';
    my $sF_minbps='27';
    my $sF_out='28';
    my $videoTs_svcname='0';
    my $videoTs_timeout='6';
    my $videoTs_encoder='0';
    my $videoTs_bittype='0';
    my $videoTs_bitstatus='1';
    my $videoTs_bitrate='250000';
    my $videoTs_bPcrBit='1';
    my $videoTs_pcrbit='25.000000';
    my $videoTs_bUnref='1';
    my $videoTs_bSync='1';
    my $videoTs_pat='1';
    my $videoTs_ProgChg='1';
    my $videoTs_ProgRem='1';
    my $videoTs_stuff='1';
    my $videoTs_stuffpid='25000';
    my $videoTs_mstuff='1';
    my $videoTs_mstuffpid='250000';
    my $videoTs_pidtype1='1';
    my $videoTs_pid1='41';
    my $videoTs_pidtype2='1';
    my $videoTs_pid2='42';
    my $videoTs_pidtype3='1';
    my $videoTs_pid3='43';
    my $videoTs_pidtype4='1';
    my $videoTs_pid4='44';
    my $alarmTab='0';
    my $videoTs_iAll='1';
    my $sF_mlr='31';
    my $bsfMLp='1';
    my $sF_mlp='32';
    my $bsfMLd='1';
    my $sF_mld='33';
    my $bsfMl15='1';
    my $sF_ccloss='34';
    my $bsfMl24='1';
    my $sF_mloss24='35';
    my $bsfMls15='1';
    my $sF_mls15='36';
    my $bsfMls24='1';
    my $sF_mls24='37';
    my $videoTs_pidtype1Act='1';
    my $videoTs_pid1Text='41';
    my $videoTs_pid1Sel='13';
    my $videoTs_pidtype2Act='1';
    my $videoTs_pid2Text='42';
    my $videoTs_pid2Sel='13';
    my $videoTs_pidtype3Act='1';
    my $videoTs_pid3Text='43';
    my $videoTs_pid3Sel='13';
    my $videoTs_pidtype4Act='1';
    my $videoTs_pid4Text='44';
    my $videoTs_pid4Sel='13';
    my $videoTs_bffrew='1';
    my $videoTs_ffrew='45';
    my $videoTs_fftype='1';
    my $etrName='new-1';
    my $etr11='1';
    my $etr12='1';
    my $etr13='1';
    my $letr13='700';
    my $etr14='1';
    my $etr15='1';
    my $letr15='1000';
    my $etr16a='1';
    my $petr16a='1';
    my $letr16a='100';
    my $etr16b='1';
    my $petr16b='2';
    my $letr16b='100';
    my $etr16c='1';
    my $petr16c='3';
    my $letr16c='100';
    my $etr16d='1';
    my $petr16d='4';
    my $letr16d='100';
    my $etr21='1';
    my $etr22='1';
    my $etr23='1';
    my $letr23a='40';
    my $letr23b='100';
    my $etr24='1';
    my $letr24='500';
    my $etr25='1';
    my $letr25='700';
    my $etr26='1';

    $self->transport_alarm_template_add( $videoTs_list, $videochar_submit, $videoTs_name, $sF_bProgCount, $sF_progCount, $videoTs_bAlign, $bsfRtplp, $sF_rtplp, $bsfRtpld, $sF_rtpld, $bsfRtptotloss, $sF_rtptotloss, $bsfRtploss24, $sF_rtploss24, $bsfls15, $sF_ls15, $bsfls24, $sF_ls24, $bsfMdi, $sF_mdi, $bsfVb, $sF_VB, $bsfLve, $sF_lve, $bsfZap, $sF_zap, $sF_bitDev, $bsfMaxBit, $bsfmaxbps, $sF_maxbps, $bsfminbps, $sF_minbps, $sF_out, $videoTs_svcname, $videoTs_timeout, $videoTs_encoder, $videoTs_bittype, $videoTs_bitstatus, $videoTs_bitrate, $videoTs_bPcrBit, $videoTs_pcrbit, $videoTs_bUnref, $videoTs_bSync, $videoTs_pat, $videoTs_ProgChg, $videoTs_ProgRem, $videoTs_stuff, $videoTs_stuffpid, $videoTs_mstuff, $videoTs_mstuffpid, $videoTs_pidtype1, $videoTs_pid1, $videoTs_pidtype2, $videoTs_pid2, $videoTs_pidtype3, $videoTs_pid3, $videoTs_pidtype4, $videoTs_pid4, $alarmTab, $videoTs_iAll, $sF_mlr, $bsfMLp, $sF_mlp, $bsfMLd, $sF_mld, $bsfMl15, $sF_ccloss, $bsfMl24, $sF_mloss24, $bsfMls15, $sF_mls15, $bsfMls24, $sF_mls24, $videoTs_pidtype1Act, $videoTs_pid1Text, $videoTs_pid1Sel, $videoTs_pidtype2Act, $videoTs_pid2Text, $videoTs_pid2Sel, $videoTs_pidtype3Act, $videoTs_pid3Text, $videoTs_pid3Sel, $videoTs_pidtype4Act, $videoTs_pid4Text, $videoTs_pid4Sel, $videoTs_bffrew, $videoTs_ffrew, $videoTs_fftype, $etrName, $etr11, $etr12, $etr13, $letr13, $etr14, $etr15, $letr15, $etr16a, $petr16a, $letr16a, $etr16b, $petr16b, $letr16b, $etr16c, $petr16c, $letr16c, $etr16d, $petr16d, $letr16d, $etr21, $etr22, $etr23, $letr23a, $letr23b, $etr24, $letr24, $etr25, $letr25, $etr26 );

    return 'OK';
}
# }}}
# {{{ set_and_check_edit_tat_flow_ip_rtp_loss_alarms_program_loss_alarm_count
sub set_and_check_edit_tat_flow_ip_rtp_loss_alarms_program_loss_alarm_count{

    my $self = shift;

    my $template_name = 'qaAutomation1';
    my $enable_disable = '1'; # check the check box
    my $check_box_is_checked = '1';
    my $new_val = '2';

    my $returnValue = "-1";

    # Set new value
    $self->edit_tat_flow_ip_rtp_loss_alarms_program_loss_alarm_count( $template_name, $enable_disable, $new_val );

    # Check Value
    $returnValue = $self->edit_tat_flow_ip_rtp_loss_alarms_program_loss_alarm_count_check( $template_name, $check_box_is_checked, $new_val );

    return $returnValue;
}
# }}}
# {{{ set_and_check_edit_tat_flow_ip_rtp_loss_alarms_ts_algn
sub set_and_check_edit_tat_flow_ip_rtp_loss_alarms_ts_algn{

    my $self = shift;

    my $template_name = 'qaAutomation1';
    my $enable_disable = '1'; # check the check box
    my $check_box_is_checked = '1';

    my $returnValue = "-1";

    # Set new value
    $self->edit_tat_flow_ip_rtp_loss_alarms_ts_algn( $template_name, $enable_disable );

    # Check Value
    $returnValue = $self->edit_tat_flow_ip_rtp_loss_alarms_ts_algn_check( $template_name, $check_box_is_checked );

    return $returnValue;
}
# }}}
# {{{ set_and_check_edit_tat_flow_ip_rtp_loss_alarms_rtp_lp
sub set_and_check_edit_tat_flow_ip_rtp_loss_alarms_rtp_lp{

    my $self = shift;

    my $template_name = 'qaAutomation1';
    my $enable_disable = '1'; # check the check box
    my $check_box_is_checked = '1';
    my $new_val = '2';

    my $returnValue = "-1";

    # Set new value
    $self->edit_tat_flow_ip_rtp_loss_alarms_rtp_lp( $template_name, $enable_disable, $new_val );

    # Check Value
    $returnValue = $self->edit_tat_flow_ip_rtp_loss_alarms_rtp_lp_check( $template_name, $check_box_is_checked, $new_val );

    return $returnValue;
}
# }}}
# {{{ set_and_check_edit_tat_flow_ip_rtp_loss_alarms_rtp_ld
sub set_and_check_edit_tat_flow_ip_rtp_loss_alarms_rtp_ld{

    my $self = shift;

    my $template_name = 'qaAutomation1';
    my $enable_disable = '1'; # check the check box
    my $check_box_is_checked = '1';
    my $new_val = '2';

    my $returnValue = "-1";

    # Set new value
    $self->edit_tat_flow_ip_rtp_loss_alarms_rtp_ld( $template_name, $enable_disable, $new_val );

    # Check Value
    $returnValue = $self->edit_tat_flow_ip_rtp_loss_alarms_rtp_ld_check( $template_name, $check_box_is_checked, $new_val );

    return $returnValue;
}
# }}}
# {{{ set_and_check_edit_tat_flow_ip_rtp_loss_alarms_rtp_se15
sub set_and_check_edit_tat_flow_ip_rtp_loss_alarms_rtp_se15{

    my $self = shift;

    my $template_name = 'qaAutomation1';
    my $enable_disable = '1'; # check the check box
    my $check_box_is_checked = '1';
    my $new_val = '2';

    my $returnValue = "-1";

    # Set new value
    $self->edit_tat_flow_ip_rtp_loss_alarms_rtp_se15( $template_name, $enable_disable, $new_val );

    # Check Value
    $returnValue = $self->edit_tat_flow_ip_rtp_loss_alarms_rtp_se15_check( $template_name, $check_box_is_checked, $new_val );

    return $returnValue;
}
# }}}
# {{{ set_and_check_edit_tat_flow_ip_rtp_loss_alarms_rtp_se24
sub set_and_check_edit_tat_flow_ip_rtp_loss_alarms_rtp_se24{

    my $self = shift;

    my $template_name = 'qaAutomation1';
    my $enable_disable = '1'; # check the check box
    my $check_box_is_checked = '1';
    my $new_val = '2';

    my $returnValue = "-1";

    # Set new value
    $self->edit_tat_flow_ip_rtp_loss_alarms_rtp_se24( $template_name, $enable_disable, $new_val );

    # Check Value
    $returnValue = $self->edit_tat_flow_ip_rtp_loss_alarms_rtp_se24_check( $template_name, $check_box_is_checked, $new_val );

    return $returnValue;
}
# }}}
# {{{ set_and_check_edit_tat_flow_ip_rtp_loss_alarms_rtp_ls15
sub set_and_check_edit_tat_flow_ip_rtp_loss_alarms_rtp_ls15{

    my $self = shift;

    my $template_name = 'qaAutomation1';
    my $enable_disable = '1'; # check the check box
    my $check_box_is_checked = '1';
    my $new_val = '2';

    my $returnValue = "-1";

    # Set new value
    $self->edit_tat_flow_ip_rtp_loss_alarms_rtp_ls15( $template_name, $enable_disable, $new_val );

    # Check Value
    $returnValue = $self->edit_tat_flow_ip_rtp_loss_alarms_rtp_ls15_check( $template_name, $check_box_is_checked, $new_val );

    return $returnValue;
}
# }}}
# {{{ set_and_check_edit_tat_flow_ip_rtp_loss_alarms_rtp_ls24
sub set_and_check_edit_tat_flow_ip_rtp_loss_alarms_rtp_ls24{

    my $self = shift;

    my $template_name = 'qaAutomation1';
    my $enable_disable = '1'; # check the check box
    my $check_box_is_checked = '1';
    my $new_val = '2';

    my $returnValue = "-1";

    # Set new value
    $self->edit_tat_flow_ip_rtp_loss_alarms_rtp_ls24( $template_name, $enable_disable, $new_val );

    # Check Value
    $returnValue = $self->edit_tat_flow_ip_rtp_loss_alarms_rtp_ls24_check( $template_name, $check_box_is_checked, $new_val );

    return $returnValue;
}
# }}}
# {{{ set_and_check_edit_tat_flow_pat_mdi_df
sub set_and_check_edit_tat_flow_pat_mdi_df{

    my $self = shift;

    my $template_name = 'qaAutomation1';
    my $enable_disable = '1'; # check the check box
    my $check_box_is_checked = '1';
    my $new_val = '2.000000';

    my $returnValue = "-1";

    # Set new value
    $self->edit_tat_flow_pat_mdi_df( $template_name, $enable_disable, $new_val );

    # Check Value
    $returnValue = $self->edit_tat_flow_pat_mdi_df_check( $template_name, $check_box_is_checked, $new_val );

    return $returnValue;
}
# }}}
# {{{ set_and_check_edit_tat_flow_pat_mdi_vbuf
sub set_and_check_edit_tat_flow_pat_mdi_vbuf{

    my $self = shift;

    my $template_name = 'qaAutomation1';
    my $enable_disable = '1'; # check the check box
    my $check_box_is_checked = '1';
    my $new_val = '2';

    my $returnValue = "-1";

    # Set new value
    $self->edit_tat_flow_pat_mdi_vbuf( $template_name, $enable_disable, $new_val );

    # Check Value
    $returnValue = $self->edit_tat_flow_pat_mdi_vbuf_check( $template_name, $check_box_is_checked, $new_val );

    return $returnValue;
}
# }}}
# {{{ set_and_check_edit_tat_flow_pat_igmp_lve
sub set_and_check_edit_tat_flow_pat_igmp_lve{

    my $self = shift;

    my $template_name = 'qaAutomation1';
    my $enable_disable = '1'; # check the check box
    my $check_box_is_checked = '1';
    my $new_val = '2';

    my $returnValue = "-1";

    # Set new value
    $self->edit_tat_flow_pat_igmp_lve( $template_name, $enable_disable, $new_val );

    # Check Value
    $returnValue = $self->edit_tat_flow_pat_igmp_lve_check( $template_name, $check_box_is_checked, $new_val );

    return $returnValue;
}
# }}}
# {{{ set_and_check_edit_tat_flow_pat_igmp_zap
sub set_and_check_edit_tat_flow_pat_igmp_zap{

    my $self = shift;

    my $template_name = 'qaAutomation1';
    my $enable_disable = '1'; # check the check box
    my $check_box_is_checked = '1';
    my $new_val = '2';

    my $returnValue = "-1";

    # Set new value
    $self->edit_tat_flow_pat_igmp_zap( $template_name, $enable_disable, $new_val );

    # Check Value
    $returnValue = $self->edit_tat_flow_pat_igmp_zap_check( $template_name, $check_box_is_checked, $new_val );

    return $returnValue;
}
# }}}
# Video Flow Alias
# {{{ set_and_check_video_flow_alias
sub set_and_check_video_flow_alias{

    my $self = shift;

    my $videoAlias_list='';
    my $cb1_='None';
    my $alias_submit='Add%2FUpdate';
    my $videoAlias_name='test-1';
    my $videoAlias_destipstatus='0';
    my $videoAlias_destip='1.1.1.1';
    my $videoAlias_destmask='255.255.255.255';
    my $videoAlias_destportstatus='1';
    my $videoAlias_destport='8888';
    my $videoAlias_srcipstatus='1';
    my $videoAlias_sourceip='192.168.10.21';
    my $videoAlias_sourcemask='255.255.255.255';
    my $videoAlias_srcportstatus='1';
    my $videoAlias_sourceport='66';
    my $videoAlias_vlanstatus='1';
    my $videoAlias_vlanid='99';
    my $videoAlias_ssrcstatus='1';
    my $videoAlias_ssrc='88';
    my $videoAlias_port='1';
    my $videoAlias_multicast='1';
    my $videoAlias_macstatus='1';
    my $videoAlias_mac='44%3A00%3A00%3A00%3A00%3A00';
    my $video_videotype='1';
    my $videoTs_list='SD';
    my $programFault_list='HD';
    my $intendedType='1';
    my $intendedBitrate='77';
    my $igmp1Sub = '1';
    my $igmp2Sub = '1';
    my $igmp3Sub = '1';
    my $igmp4Sub = '1';
    my $igmp5Sub = '1';
    my $igmp6Sub = '1';
    my $igmp7Sub = '1';
    my $igmp8Sub = '1';
    my $igmp9Sub = '1';
    my $igmp10Sub = '1';
    my $igmp11Sub = '1';
    my $igmp12Sub = '1';
    my $igmp13Sub = '1';
    my $igmp14Sub = '1';
    my $igmp15Sub = '1';

    $self->video_flow_alias_add( $videoAlias_list,$cb1_,$alias_submit,$videoAlias_name,$videoAlias_destipstatus,$videoAlias_destip,$videoAlias_destmask,$videoAlias_destportstatus,$videoAlias_destport,$videoAlias_srcipstatus,$videoAlias_sourceip,$videoAlias_sourcemask,$videoAlias_srcportstatus, $videoAlias_sourceport,$videoAlias_vlanstatus, $videoAlias_vlanid,$videoAlias_ssrcstatus, $videoAlias_ssrc,$videoAlias_port,$videoAlias_multicast,$videoAlias_macstatus, $videoAlias_mac,$video_videotype,$videoTs_list,$programFault_list,$intendedType,$intendedBitrate, $igmp1Sub, $igmp2Sub, $igmp3Sub, $igmp4Sub, $igmp5Sub, $igmp6Sub, $igmp7Sub, $igmp8Sub, $igmp9Sub, $igmp10Sub, $igmp11Sub, $igmp12Sub, $igmp13Sub, $igmp14Sub, $igmp15Sub );

    return 'OK';
}
# }}}
# Vide Program Alias
# {{{ set_and_check_video_program_alias
sub set_and_check_video_program_alias{

    my $self = shift;

    my $videoChan_list ='0';
    my $cb1_ = '';
    my $videochan_confirm_ = 'Add%2FUpdate';
    my $videoChan_progname = 'test-2';
    my $videoName_list = '19';
    my $videoChan_program = '3';
    my $videoChan_prognumber = '88';
    my $videoChan_device = 'aaaa';
    my $videoChan_boffair = '1';
    my $videoChan_offstart = '00%3A00';
    my $videoChan_offend = '00%3A00';
    my $programFault_list = '1';
    my $programOffFault_list = '1';
    my $videoChan_MediaType = '1';

    $self->video_program_alias_add( $videoChan_list, $cb1_, $videochan_confirm_, $videoChan_progname, $videoName_list, $videoChan_program, $videoChan_prognumber, $videoChan_device, $videoChan_boffair, $videoChan_offstart, $videoChan_offend, $programFault_list, $programOffFault_list, $videoChan_MediaType );

    return 'OK';
}
# }}}
##
##
sub test_function{

    my $self = shift;

    print "dropdown transport: " . $self->get_select_dropdown_value( 'transport_alarm', '0', 'new-1' ) . "\n"; 

    print "droptdown program: " . $self->get_select_dropdown_value( 'program_alarm', '0', 'new-1' ) . "\n";
    my $num1 = $self->get_select_dropdown_value( 'program_alarm', 'none', 'new-1' );
    print "program input text: " . $self->get_text_input_value( 'program_alarm', $num1, 'progF_mlr' ) . "\n";

    print "program checkbox: " . $self->get_checkbox_value( 'program_alarm', $num1, 'bpfMls24' ) . "\n";

    print "management_port IP: " . $self->get_text_input_value( 'management_port', 'none', 'system_ipaddress' ) . "\n";

    print "get_video_flow_alias_list_number: " . $self->get_video_flow_alias_list_number( 'test1' ) . "\n";

    print "get_video_program_alias_list_number: " . $self->get_video_program_alias_list_number( 'test-1' ) . "\n";

    return 'OK';
}
1;
