#!/usr/bin/perl
# vim: set expandtab tabstop=4 shiftwidth=4 softtabstop=4 foldmethod=marker: #

#
# A Class to perform QA testing on IQ Probes
#

package QA_PROBES;
use strict;
use lib '/opt/probe-web-automation';
use Switch;
use IQ;

# Probe Connection Functions
# {{{ new
sub new {
        my $self  = {};

#	$self->{PAGE_IP} = undef;
#    $self->{mech} = undef;
#    $self->{probe_type} = undef;

    $self->{IQ} = undef;    

        bless($self);
        return $self;
}
# }}}
sub test_runner{
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

    # Start up the IQ object which is the one interacting with the probe
    $self->{IQ} = new IQ; 

    $self->{IQ}->set_probe_type( $probe_type );
    $self->{IQ}->set_page_ip( $probe_ip );

    $self->{IQ}->start_mech();

    $self->{IQ}->login( $admin_user, $admin_pass );

    # Run the test 
    my $test_output = $self->$test_to_run( $additional_vars );

    return $test_output;
}
#
#
#
#
#
sub check_main_menu {

    my $self = shift;

    my $url_string = '/status/main_menu.html';

    my $returnValue = 'Not OK';

    $self->{IQ}->{mech}->get("http://".$self->{IQ}->{PAGE_IP}.$url_string);

    my $page_content = $self->{IQ}->{mech}->content();

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

    $self->{IQ}->{mech}->get("http://".$self->{IQ}->{PAGE_IP}.$url_string);

    my $page_content = $self->{IQ}->{mech}->content();

    # Checking Page
    if( $page_content =~ /SYSTEM STATUS/g && $page_content =~ /sysstatus\.html/g ){
        $returnValue = 'OK';
    }

    # This page holds the body with the information about system status
    $url_string = '/dynamic/sysstatus.html';

    if( $returnValue eq 'OK' ){

        $returnValue = 'Not OK: 2';

        $self->{IQ}->{mech}->get("http://".$self->{IQ}->{PAGE_IP}.$url_string);

        $page_content = $self->{IQ}->{mech}->content();

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

    $self->{IQ}->{mech}->get("http://".$self->{IQ}->{PAGE_IP}.$url_string);

    my $page_content = $self->{IQ}->{mech}->content();

    # Checking Page
    if( $page_content =~ /RMON/g && $page_content =~ /rmonstats\.html/g ){
        $returnValue = 'OK';
    }

    # This page holds the body with the information about system status
    $url_string = '/dynamic/rmonstats.html';

    if( $returnValue eq 'OK' ){
        $returnValue = 'Not OK: 2';

        $self->{IQ}->{mech}->get("http://".$self->{IQ}->{PAGE_IP}.$url_string);

        $page_content = $self->{IQ}->{mech}->content();

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

    $self->{IQ}->{mech}->get("http://".$self->{IQ}->{PAGE_IP}.$url_string);

    my $page_content = $self->{IQ}->{mech}->content();

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

    $self->{IQ}->{mech}->get("http://".$self->{IQ}->{PAGE_IP}.$url_string);

    my $page_content = $self->{IQ}->{mech}->content();

    # Checking Page
    if( $page_content =~ /Media Overview/g && $page_content =~ /mediaview\.html/g ){
        $returnValue = 'OK';
    }

    # This page holds the body with the information about system status
    $url_string = '/dynamic/mediaview.html';

    if( $returnValue eq 'OK' ){
        $returnValue = 'Not OK: 2';

        $self->{IQ}->{mech}->get("http://".$self->{IQ}->{PAGE_IP}.$url_string);

        $page_content = $self->{IQ}->{mech}->content();

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

    $self->{IQ}->{mech}->get("http://".$self->{IQ}->{PAGE_IP}.$url_string);

    my $page_content = $self->{IQ}->{mech}->content();

    # Checking Page
    if( $page_content =~ /FLOW CENSUS/g && $page_content =~ /flowcensus\.html/g ){
        $returnValue = 'OK';
    }

    # This page holds the body with the information about system status
    $url_string = '/dynamic/flowcensus.html';

    if( $returnValue eq 'OK' ){
        $returnValue = 'Not OK: 2';

        $self->{IQ}->{mech}->get("http://".$self->{IQ}->{PAGE_IP}.$url_string);

        $page_content = $self->{IQ}->{mech}->content();

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

    $self->{IQ}->{mech}->get("http://".$self->{IQ}->{PAGE_IP}.$url_string);

    my $page_content = $self->{IQ}->{mech}->content();

    # Checking Page
    if( $page_content =~ /PROGRAM VIEW/g && $page_content =~ /censuscombo\.html/g ){
        $returnValue = 'OK';
    }

    # This page holds the body with the information about system status
    $url_string = '/dynamic/censuscombo.html';

    if( $returnValue eq 'OK' ){
        $returnValue = 'Not OK: 2';

        $self->{IQ}->{mech}->get("http://".$self->{IQ}->{PAGE_IP}.$url_string);

        $page_content = $self->{IQ}->{mech}->content();

        # Checking Page
        if( $page_content =~ /xml/g && $page_content =~ /standalone/g ){
            $returnValue = 'OK';
        }

        # This page holds the body with the information about system status
        $url_string = '/dynamic/pgmdetails.html';

        if( $returnValue eq 'OK' ){
            $returnValue = 'Not OK: 3';

            $self->{IQ}->{mech}->get("http://".$self->{IQ}->{PAGE_IP}.$url_string);

            $page_content = $self->{IQ}->{mech}->content();

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

    $self->{IQ}->{mech}->get("http://".$self->{IQ}->{PAGE_IP}.$url_string);

    my $page_content = $self->{IQ}->{mech}->content();

    # Checking Page
    if( $page_content =~ /FLOW STATUS/g && $page_content =~ /pmstats\.html/g ){
        $returnValue = 'OK';
    }

    # This page holds the body with the information about system status
    $url_string = '/dynamic/pmstats.html';

    if( $returnValue eq 'OK' ){

        $returnValue = 'Not OK: 2';

        $self->{IQ}->{mech}->get("http://".$self->{IQ}->{PAGE_IP}.$url_string);

        $page_content = $self->{IQ}->{mech}->content();

# Checking Page
        if( $page_content =~ /table/g && $page_content =~ /tbody/g ){
            $returnValue = 'OK';
        }

# This page holds the body with the information about system status
        $url_string = '/dynamic/streamstats.html';

        if( $returnValue eq 'OK' ){

            $returnValue = 'Not OK: 3';

            $self->{IQ}->{mech}->get("http://".$self->{IQ}->{PAGE_IP}.$url_string);

            $page_content = $self->{IQ}->{mech}->content();

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

    $self->{IQ}->program_alarm_template_add( $programFault_list, $programFault_submit , $programFault_template , $progF_mlr , $bpfMLp , $progF_Lp , $bpfMLd , $progF_Ld , $bpfMLoss15 , $progF_ccloss, $bpfMLoss, $progF_loss24, $bpfMls24, $progF_mls24, $bpfMls15, $progF_mls15, $progF_control, $progF_bscramble, $progF_scramble, $progF_outsoak, $progF_soak, $progF_iAudio, $progF_pidtype1, $progF_pid1, $progF_pidtype2, $progF_pid2, $progF_pidtype3, $progF_pid3, $progF_pidtype1Act, $progF_pid1Text, $progF_pid1Sel, $progF_bPid1, $progF_thr1, $progF_bmPid1, $progF_mthr1, $progF_pidtype2Act, $progF_pid2Text, $progF_pid2Sel, $progF_bPid2, $progF_thr2, $progF_bmPid2, $progF_mthr2, $progF_pidtype3Act, $progF_pid3Text, $progF_pid3Sel, $progF_bPid3, $progF_thr3, $progF_bmPid3, $progF_mthr3, $progF_Ovideo, $progF_ovidpid, $progF_video, $progF_vidpid, $progF_mvideo, $progF_mvidpid, $progF_OAudio, $progF_oaudpid, $progF_audio, $progF_audpid, $progF_maudio, $progF_maudpid, $progF_pmt, $progF_pcr );

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
    $self->{IQ}->pat_mdi_mlr_edit( $template_name, $mdi_mlr_value );

    # Check Value
    $returnValue = $self->{IQ}->pat_mdi_mlr_check( $template_name, $mdi_mlr_value );

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
    $self->{IQ}->pat_pmla_mlt15( $template_name, $enable_disable, $new_val );

    # Check Value
    $returnValue = $self->{IQ}->pat_pmla_mlt15_check( $template_name, $check_box_is_checked, $new_val );

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
    $self->{IQ}->pat_pmla_mls_lp( $template_name, $enable_disable, $new_val );

    # Check Value
    $returnValue = $self->{IQ}->pat_pmla_mls_lp_check( $template_name, $check_box_is_checked, $new_val );

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
    $self->{IQ}->pat_pmla_mls_ld( $template_name, $enable_disable, $new_val );

    # Check Value
    $returnValue = $self->{IQ}->pat_pmla_mls_ld_check( $template_name, $check_box_is_checked, $new_val );

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
    $self->{IQ}->pat_pmla_mls24( $template_name, $enable_disable, $new_val );

    # Check Value
    $returnValue = $self->{IQ}->pat_pmla_mls24_check( $template_name, $check_box_is_checked, $new_val );

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
    $self->{IQ}->pat_pmla_mls15( $template_name, $enable_disable, $new_val );

    # Check Value
    $returnValue = $self->{IQ}->pat_pmla_mls15_check( $template_name, $check_box_is_checked, '9');#$new_val );

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
    $self->{IQ}->edit_pat_pma_program_scramble_state( $template_name, $enable_disable, $new_val );

    # Check Value
    $returnValue = $self->{IQ}->edit_pat_pma_program_scramble_state_check( $template_name, $check_box_is_checked, $new_val );

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
    $self->{IQ}->edit_pat_pma_pid_monitor_status( $template_name, $new_val );

    # Check Value
    $returnValue = $self->{IQ}->edit_pat_pma_pid_monitor_status_check( $template_name, $new_val );

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
    $self->{IQ}->edit_pat_pma_pid_alarm_trigger_period( $template_name, $new_val );

    # Check Value
    $returnValue = $self->{IQ}->edit_pat_pma_pid_alarm_trigger_period_check( $template_name, $new_val );

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
    $self->{IQ}->edit_pat_pma_ignore_secondary_audio_pid( $template_name, $enable_disable );

    # Check Value
    $returnValue = $self->{IQ}->edit_pat_pma_ignore_secondary_audio_pid_check( $template_name, $enable_disable );

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
    $self->{IQ}->edit_ppbma_video_outage_val( $template_name, $enable_disable, $new_val );

    # Check Value
    $returnValue = $self->{IQ}->edit_ppbma_video_outage_val_check( $template_name, $check_box_is_checked, $new_val );

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
    $self->{IQ}->edit_ppbma_video_min_val( $template_name, $enable_disable, $new_val );

    # Check Value
    $returnValue = $self->{IQ}->edit_ppbma_video_min_val_check( $template_name, $check_box_is_checked, $new_val );

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
    $self->{IQ}->edit_ppbma_video_max_val( $template_name, $enable_disable, $new_val );

    # Check Value
    $returnValue = $self->{IQ}->edit_ppbma_video_max_val_check( $template_name, $check_box_is_checked, $new_val );

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
    $self->{IQ}->edit_ppbma_audo_outage_val( $template_name, $enable_disable, $new_val );

    # Check Value
    $returnValue = $self->{IQ}->edit_ppbma_audo_outage_val_check( $template_name, $check_box_is_checked, $new_val );

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
    $self->{IQ}->edit_ppbma_audio_min_val( $template_name, $enable_disable, $new_val );

    # Check Value
    $returnValue = $self->{IQ}->edit_ppbma_audio_min_val_check( $template_name, $check_box_is_checked, $new_val );

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
    $self->{IQ}->edit_ppbma_audio_max_val( $template_name, $enable_disable, $new_val );

    # Check Value
    $returnValue = $self->{IQ}->edit_ppbma_audio_max_val_check( $template_name, $check_box_is_checked, $new_val );

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
    $self->{IQ}->edit_ppbma_pmt_pid_outage( $template_name, $enable_disable );

    # Check Value
    $returnValue = $self->{IQ}->edit_ppbma_pmt_pid_outage_check( $template_name, $check_box_is_checked );

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
    $self->{IQ}->edit_ppbma_pmt_pcr_pid_outage( $template_name, $enable_disable );

    # Check Value
    $returnValue = $self->{IQ}->edit_ppbma_pmt_pcr_pid_outage_check( $template_name, $check_box_is_checked );

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

    $self->{IQ}->transport_alarm_template_add( $videoTs_list, $videochar_submit, $videoTs_name, $sF_bProgCount, $sF_progCount, $videoTs_bAlign, $bsfRtplp, $sF_rtplp, $bsfRtpld, $sF_rtpld, $bsfRtptotloss, $sF_rtptotloss, $bsfRtploss24, $sF_rtploss24, $bsfls15, $sF_ls15, $bsfls24, $sF_ls24, $bsfMdi, $sF_mdi, $bsfVb, $sF_VB, $bsfLve, $sF_lve, $bsfZap, $sF_zap, $sF_bitDev, $bsfMaxBit, $bsfmaxbps, $sF_maxbps, $bsfminbps, $sF_minbps, $sF_out, $videoTs_svcname, $videoTs_timeout, $videoTs_encoder, $videoTs_bittype, $videoTs_bitstatus, $videoTs_bitrate, $videoTs_bPcrBit, $videoTs_pcrbit, $videoTs_bUnref, $videoTs_bSync, $videoTs_pat, $videoTs_ProgChg, $videoTs_ProgRem, $videoTs_stuff, $videoTs_stuffpid, $videoTs_mstuff, $videoTs_mstuffpid, $videoTs_pidtype1, $videoTs_pid1, $videoTs_pidtype2, $videoTs_pid2, $videoTs_pidtype3, $videoTs_pid3, $videoTs_pidtype4, $videoTs_pid4, $alarmTab, $videoTs_iAll, $sF_mlr, $bsfMLp, $sF_mlp, $bsfMLd, $sF_mld, $bsfMl15, $sF_ccloss, $bsfMl24, $sF_mloss24, $bsfMls15, $sF_mls15, $bsfMls24, $sF_mls24, $videoTs_pidtype1Act, $videoTs_pid1Text, $videoTs_pid1Sel, $videoTs_pidtype2Act, $videoTs_pid2Text, $videoTs_pid2Sel, $videoTs_pidtype3Act, $videoTs_pid3Text, $videoTs_pid3Sel, $videoTs_pidtype4Act, $videoTs_pid4Text, $videoTs_pid4Sel, $videoTs_bffrew, $videoTs_ffrew, $videoTs_fftype, $etrName, $etr11, $etr12, $etr13, $letr13, $etr14, $etr15, $letr15, $etr16a, $petr16a, $letr16a, $etr16b, $petr16b, $letr16b, $etr16c, $petr16c, $letr16c, $etr16d, $petr16d, $letr16d, $etr21, $etr22, $etr23, $letr23a, $letr23b, $etr24, $letr24, $etr25, $letr25, $etr26 );

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
    $self->{IQ}->edit_tat_flow_ip_rtp_loss_alarms_program_loss_alarm_count( $template_name, $enable_disable, $new_val );

    # Check Value
    $returnValue = $self->{IQ}->edit_tat_flow_ip_rtp_loss_alarms_program_loss_alarm_count_check( $template_name, $check_box_is_checked, $new_val );

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
    $self->{IQ}->edit_tat_flow_ip_rtp_loss_alarms_ts_algn( $template_name, $enable_disable );

    # Check Value
    $returnValue = $self->{IQ}->edit_tat_flow_ip_rtp_loss_alarms_ts_algn_check( $template_name, $check_box_is_checked );

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
    $self->{IQ}->edit_tat_flow_ip_rtp_loss_alarms_rtp_lp( $template_name, $enable_disable, $new_val );

    # Check Value
    $returnValue = $self->{IQ}->edit_tat_flow_ip_rtp_loss_alarms_rtp_lp_check( $template_name, $check_box_is_checked, $new_val );

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
    $self->{IQ}->edit_tat_flow_ip_rtp_loss_alarms_rtp_ld( $template_name, $enable_disable, $new_val );

    # Check Value
    $returnValue = $self->{IQ}->edit_tat_flow_ip_rtp_loss_alarms_rtp_ld_check( $template_name, $check_box_is_checked, $new_val );

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
    $self->{IQ}->edit_tat_flow_ip_rtp_loss_alarms_rtp_se15( $template_name, $enable_disable, $new_val );

    # Check Value
    $returnValue = $self->{IQ}->edit_tat_flow_ip_rtp_loss_alarms_rtp_se15_check( $template_name, $check_box_is_checked, $new_val );

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
    $self->{IQ}->edit_tat_flow_ip_rtp_loss_alarms_rtp_se24( $template_name, $enable_disable, $new_val );

    # Check Value
    $returnValue = $self->{IQ}->edit_tat_flow_ip_rtp_loss_alarms_rtp_se24_check( $template_name, $check_box_is_checked, $new_val );

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
    $self->{IQ}->edit_tat_flow_ip_rtp_loss_alarms_rtp_ls15( $template_name, $enable_disable, $new_val );

    # Check Value
    $returnValue = $self->{IQ}->edit_tat_flow_ip_rtp_loss_alarms_rtp_ls15_check( $template_name, $check_box_is_checked, $new_val );

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
    $self->{IQ}->edit_tat_flow_ip_rtp_loss_alarms_rtp_ls24( $template_name, $enable_disable, $new_val );

    # Check Value
    $returnValue = $self->{IQ}->edit_tat_flow_ip_rtp_loss_alarms_rtp_ls24_check( $template_name, $check_box_is_checked, $new_val );

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
    $self->{IQ}->edit_tat_flow_pat_mdi_df( $template_name, $enable_disable, $new_val );

    # Check Value
    $returnValue = $self->{IQ}->edit_tat_flow_pat_mdi_df_check( $template_name, $check_box_is_checked, $new_val );

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
    $self->{IQ}->edit_tat_flow_pat_mdi_vbuf( $template_name, $enable_disable, $new_val );

    # Check Value
    $returnValue = $self->{IQ}->edit_tat_flow_pat_mdi_vbuf_check( $template_name, $check_box_is_checked, $new_val );

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
    $self->{IQ}->edit_tat_flow_pat_igmp_lve( $template_name, $enable_disable, $new_val );

    # Check Value
    $returnValue = $self->{IQ}->edit_tat_flow_pat_igmp_lve_check( $template_name, $check_box_is_checked, $new_val );

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
    $self->{IQ}->edit_tat_flow_pat_igmp_zap( $template_name, $enable_disable, $new_val );

    # Check Value
    $returnValue = $self->{IQ}->edit_tat_flow_pat_igmp_zap_check( $template_name, $check_box_is_checked, $new_val );

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

    $self->{IQ}->video_flow_alias_add( $videoAlias_list,$cb1_,$alias_submit,$videoAlias_name,$videoAlias_destipstatus,$videoAlias_destip,$videoAlias_destmask,$videoAlias_destportstatus,$videoAlias_destport,$videoAlias_srcipstatus,$videoAlias_sourceip,$videoAlias_sourcemask,$videoAlias_srcportstatus, $videoAlias_sourceport,$videoAlias_vlanstatus, $videoAlias_vlanid,$videoAlias_ssrcstatus, $videoAlias_ssrc,$videoAlias_port,$videoAlias_multicast,$videoAlias_macstatus, $videoAlias_mac,$video_videotype,$videoTs_list,$programFault_list,$intendedType,$intendedBitrate, $igmp1Sub, $igmp2Sub, $igmp3Sub, $igmp4Sub, $igmp5Sub, $igmp6Sub, $igmp7Sub, $igmp8Sub, $igmp9Sub, $igmp10Sub, $igmp11Sub, $igmp12Sub, $igmp13Sub, $igmp14Sub, $igmp15Sub );

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

    $self->{IQ}->video_program_alias_add( $videoChan_list, $cb1_, $videochan_confirm_, $videoChan_progname, $videoName_list, $videoChan_program, $videoChan_prognumber, $videoChan_device, $videoChan_boffair, $videoChan_offstart, $videoChan_offend, $programFault_list, $programOffFault_list, $videoChan_MediaType );

    return 'OK';
}
# }}}
##
##
sub test_function{

    my $self = shift;

    print "dropdown transport: " . $self->{IQ}->get_select_dropdown_value( 'transport_alarm', '0', 'new-1' ) . "\n"; 

    print "droptdown program: " . $self->{IQ}->get_select_dropdown_value( 'program_alarm', '0', 'new-1' ) . "\n";
    my $num1 = $self->{IQ}->get_select_dropdown_value( 'program_alarm', 'none', 'new-1' );
    print "program input text: " . $self->{IQ}->get_text_input_value( 'program_alarm', $num1, 'progF_mlr' ) . "\n";

    print "program checkbox: " . $self->{IQ}->get_checkbox_value( 'program_alarm', $num1, 'bpfMls24' ) . "\n";

    print "management_port IP: " . $self->{IQ}->get_text_input_value( 'management_port', 'none', 'system_ipaddress' ) . "\n";

    print "get_video_flow_alias_list_number: " . $self->{IQ}->get_video_flow_alias_list_number( 'test1' ) . "\n";

    print "get_video_program_alias_list_number: " . $self->{IQ}->get_video_program_alias_list_number( 'test-1' ) . "\n";

    return 'OK';
}
#
#
#
#
1;
