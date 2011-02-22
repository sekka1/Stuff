#!/usr/bin/perl
# vim: set expandtab tabstop=4 shiftwidth=4 softtabstop=4 foldmethod=marker: #

package Provisioning;
use strict;
use lib '/opt/probe-web-automation';
use IQ;
use Switch;

# {{{ new
sub new {
	my $self  = {};

    $self->{filename} = $_[1];
	$self->{FILE} = undef;

    $self->{ProbeList} = ();

    $self->{User} = $_[2];
    $self->{Password} = $_[3];

    $self->{IQ} = undef;

    bless($self); 
    return $self;
}
# }}}
sub open_file {

	my $self = shift;

	#open( $self->{FILE}, $self->{filename} ) || die("Could not open file!");

    #$self->{FileLines} = $self->{FILE};
}
sub probe_list {
# Probe list giving in a CSV format

    my $self = shift;

    my $list = $_[0];

    $self->{ProbeList} = $list;
    #$self->{ProbeList} = split( /,/, $list );

}
sub parse_file {

	my $self = shift;

    # Open File
    open( FILE, $self->{filename} ) || die("Could not open file!");

    my @file_content = <FILE>;

    # Separate the probe's ip list
    my @probe_list = split( /,/, $self->{ProbeList} );

    foreach my $aProbe ( @probe_list ){

print "Provisioning Probe: $aProbe - " . $self->{User} . " - " .  $self->{Password} . "\n";

        # Start the IQ Probe automation object
        $self->start_iq( $aProbe, $self->{User}, $self->{Password} );

        # Save these for use with every run of the edit probe commands
        my $alarm_type = '';
        my $template_name = '';

        foreach my $line ( @file_content ){

            # Only run lines that are not comments.  Comments lines starts with a '#'
            if( $line !~ /^#/ ){ 

                # Split by the equal sign
                my @name_val = split( /=/, $line );

                # Find alarm type to edit
                if( $name_val[0] =~ /AlarmType/ ){
                    $alarm_type = $name_val[0];
                }
                # Find template name
                elsif( $name_val[0] =~ /TemplateName/ ){
                    $template_name = $name_val[1];
                    $template_name =~ s/^\s*(\S*(?:\s+\S+)*)\s*$/$1/; # Trim leading and trailing spaces
                }
                # Run command
                else {

                    $self->run_set_value( $template_name, $name_val[0], $name_val[1] );
                }

            }
        }

        # Reset the IQ object
        $self->{IQ} = undef;
    }
}
sub run_set_value {
# Sets the value in the probe using the IQ.pm module

	my $self = shift;

    my $template_name = $_[0];
    my $attrib_name = $_[1];
    my $attrib_value = $_[2];

#    print "$template_name  -  $attrib_name   -  $attrib_value   \n"; 

    # Separate Attribute values: in the form of <enable switch> <new value>
    my @attribe_value_split = split( /,/, $attrib_value );
    my $enable_switch = $self->get_enable_switch_mapping( $attribe_value_split[0] );
    my $new_value = $attribe_value_split[1];

    # Get the real IQ function name associated with the config name which is shorter
    my $iq_function_name = $self->get_run_iq_function_name( $attrib_name );

    print $iq_function_name . "  function name\n";

    if( $iq_function_name !~ /none/ ){

        # Run the function that corespsonds to the IQ class mapped to the user config file
        $self->{IQ}->$iq_function_name( $template_name, $enable_switch, $new_value ); 
    }
}
sub get_enable_switch_mapping {
# Returns the mapping of what the user puts in config file to turn the check box
# on or off to the numerical value that the web automation get string wants 1 or 0.
# Also if the value doesnt map to on or off, then this is probably one that has no
# check box so just return the orig value

    my $self = shift;

    my $config_file_value = $_[0];  # on or off
    my $web_enable_switch_value = $config_file_value;  # 1 = on, 0 = off

    if( $config_file_value =~ /on/ ){
        $web_enable_switch_value = 1;
    } elsif ( $config_file_value =~ /off/ ){
        $web_enable_switch_value = 0;
    }

    return $web_enable_switch_value;
}
sub get_run_iq_function_name {

    my $self = shift;

    my $function_name = $_[0];
    my $iq_function_name = 'none';

    switch( $function_name ){

        case 'pmla_mdi-mlr' { $iq_function_name = 'pat_mdi_mlr_edit' }
        case 'pmla_mlt-15' { $iq_function_name = 'pat_pmla_mlt15' }
        case 'pmla_mls-lp' { $iq_function_name = 'pat_pmla_mls_lp' }
        case 'pmla_mlt-24' { $iq_function_name = 'pat_pmla_mlt24' }
        case 'pmla_mls-ld' { $iq_function_name = 'pat_pmla_mls_ld' }
        case 'pmla_mls-24' { $iq_function_name = 'pat_pmla_mls24' }
        case 'pmla_mls-15' { $iq_function_name = 'pat_pmla_mls15' }
        ##
        ## Adding other functions on airplane...
        case 'pat_pma_program_scramble_state' { $iq_function_name = 'edit_pat_pma_program_scramble_state' }
        case 'pat_pma_pid_monitor_status' { $iq_function_name = 'edit_pat_pma_pid_monitor_status' }
        case 'pat_pma_pid_alarm_trigger_period' { $iq_function_name = 'edit_pat_pma_pid_alarm_trigger_period' }
        case 'pat_pma_ignore_secondary_audio_pid' { $iq_function_name = 'edit_pat_pma_ignore_secondary_audio_pid' }
        case 'pat_pma_scte35_detection' { $iq_function_name = 'edit_pat_pma_scte35_detection' }
        case 'pat_pma_max_inactivity_period_scte35' { $iq_function_name = 'edit_pat_pma_max_inactivity_period_scte35' }
        case 'ppbma_video_outage_val' { $iq_function_name = 'edit_ppbma_video_outage_val' }
        case 'ppbma_video_min_val' { $iq_function_name = 'edit_ppbma_video_min_val' }
        case 'ppbma_video_max_val' { $iq_function_name = 'edit_ppbma_video_max_val' }
        case 'ppbma_audo_outage_val' { $iq_function_name = 'edit_ppbma_audo_outage_val' }
        case 'ppbma_audio_min_val' { $iq_function_name = 'edit_ppbma_audio_min_val' }
        case 'ppbma_audio_max_val' { $iq_function_name = 'edit_ppbma_audio_max_val' }
        case 'ppbma_pmt_pid_outage' { $iq_function_name = 'edit_ppbma_pmt_pid_outage' }
        case 'ppbma_pmt_pcr_pid_outage' { $iq_function_name = 'edit_ppbma_pmt_pcr_pid_outage' }
        case 'tat_flow_ip_rtp_loss_alarms_program_loss_alarm_count' { $iq_function_name = 'edit_tat_flow_ip_rtp_loss_alarms_program_loss_alarm_count' }
        case 'tat_flow_ip_rtp_loss_alarms_ts_algn' { $iq_function_name = 'edit_tat_flow_ip_rtp_loss_alarms_ts_algn' }
        case 'tat_flow_ip_rtp_loss_alarms_rtp_lp' { $iq_function_name = 'edit_tat_flow_ip_rtp_loss_alarms_rtp_lp' }
        case 'tat_flow_ip_rtp_loss_alarms_rtp_ld' { $iq_function_name = 'edit_tat_flow_ip_rtp_loss_alarms_rtp_ld' }
        case 'tat_flow_ip_rtp_loss_alarms_rtp_se15' { $iq_function_name = 'edit_tat_flow_ip_rtp_loss_alarms_rtp_se15' }
        case 'tat_flow_ip_rtp_loss_alarms_rtp_se24' { $iq_function_name = 'edit_tat_flow_ip_rtp_loss_alarms_rtp_se24' }
        case 'tat_flow_ip_rtp_loss_alarms_rtp_ls15' { $iq_function_name = 'edit_tat_flow_ip_rtp_loss_alarms_rtp_ls15' }
        case 'tat_flow_ip_rtp_loss_alarms_rtp_ls24' { $iq_function_name = 'edit_tat_flow_ip_rtp_loss_alarms_rtp_ls24' }
        case 'tat_flow_ip_rtp_loss_alarms_rtp_dup' { $iq_function_name = 'edit_tat_flow_ip_rtp_loss_alarms_rtp_dup' }
        case 'tat_flow_ip_rtp_loss_alarms_rtp_oos' { $iq_function_name = 'edit_tat_flow_ip_rtp_loss_alarms_rtp_oos' }
        case 'tat_flow_pat_mdi_df' { $iq_function_name = 'edit_tat_flow_pat_mdi_df' }
        case 'tat_flow_pat_mdi_vbuf' { $iq_function_name = 'edit_tat_flow_pat_mdi_vbuf' }
        case 'tat_flow_pat_igmp_lve' { $iq_function_name = 'edit_tat_flow_pat_igmp_lve' }
        case 'tat_flow_pat_igmp_zap' { $iq_function_name = 'edit_tat_flow_pat_igmp_zap' }
        case 'tat_flow_pat_ip_sbr_radio_button' { $iq_function_name = 'edit_tat_flow_pat_ip_sbr_radio_button' }
        case 'tat_flow_pat_ip_sbr_deviation_percent_value' { $iq_function_name = 'edit_tat_flow_pat_ip_sbr_deviation_percent_value' }
        case 'tat_flow_pat_ip_sbr_ip_sbrmx' { $iq_function_name = 'edit_tat_flow_pat_ip_sbr_ip_sbrmx' }
        case 'tat_flow_pat_ip_sbr_ip_sbrmn' { $iq_function_name = 'edit_tat_flow_pat_ip_sbr_ip_sbrmn' }
        case 'tat_flow_pat_vido_los' { $iq_function_name = 'edit_tat_flow_pat_vido_los' }
        case 'tat_ts_general_ts_video_servise_name_detection' { $iq_function_name = 'edit_tat_ts_general_ts_video_servise_name_detection' }
        case 'tat_ts_general_stream_end_timeout' { $iq_function_name = 'edit_tat_ts_general_stream_end_timeout' }
        case 'tat_ts_general_video_source' { $iq_function_name = 'edit_tat_ts_general_video_source' }
        case 'tat_ts_general_bit_rate_type' { $iq_function_name = 'edit_tat_ts_general_bit_rate_type' }
        case 'tat_ts_general_stream_bit_rate' { $iq_function_name = 'edit_tat_ts_general_stream_bit_rate' }
        case 'tat_ts_general_v_tsb' { $iq_function_name = 'edit_tat_ts_general_v_tsb' }
        case 'tat_ts_general_unref_pid' { $iq_function_name = 'edit_tat_ts_general_unref_pid' }
        case 'tat_ts_general_ts_snc' { $iq_function_name = 'edit_tat_ts_general_ts_snc' }
        case 'tat_ts_general_program_changes_traps' { $iq_function_name = 'edit_tat_ts_general_program_changes_traps' }
        case 'tat_ts_general_pat_pid_outage' { $iq_function_name = 'edit_tat_ts_general_pat_pid_outage' }
        case 'tat_ts_nppm_monitoring_level' { $iq_function_name = 'edit_tat_ts_nppm_monitoring_level' }
        case 'tat_ts_nppm_mdi_mlr' { $iq_function_name = 'edit_tat_ts_nppm_mdi_mlr' }
        case 'tat_ts_nppm_mls_lp' { $iq_function_name = 'edit_tat_ts_nppm_mls_lp' }
        case 'tat_ts_nppm_mls_ld' { $iq_function_name = 'edit_tat_ts_nppm_mls_ld' }
        case 'tat_ts_nppm_mlt_15' { $iq_function_name = 'edit_tat_ts_nppm_mlt_15' }
        case 'tat_ts_nppm_mlt_24' { $iq_function_name = 'edit_tat_ts_nppm_mlt_24' }
        case 'tat_ts_nppm_mls_15' { $iq_function_name = 'edit_tat_ts_nppm_mls_15' }
        case 'tat_ts_nppm_mls_24' { $iq_function_name = 'edit_tat_ts_nppm_mls_24' }
        case 'tat_ts_spt_min' { $iq_function_name = 'edit_tat_ts_spt_min' }
        case 'tat_ts_spt_max' { $iq_function_name = 'edit_tat_ts_spt_max' }
        case 'tat_ts_medffr_checkbox' { $iq_function_name = 'edit_tat_ts_medffr_checkbox' }
        case 'tat_ts_medffr_radio_and_value' { $iq_function_name = 'edit_tat_ts_medffr_radio_and_value' }
        case 'tat_ts_tsup_user_pid_1' { $iq_function_name = 'edit_tat_ts_tsup_user_pid_1' }
        case 'tat_etsi_fp_ts_sync_loss' { $iq_function_name = 'edit_tat_etsi_fp_ts_sync_loss' }
        case 'tat_etsi_fp_sync_byte_error' { $iq_function_name = 'edit_tat_etsi_fp_sync_byte_error' }
        case 'tat_etsi_fp_pat_error' { $iq_function_name = 'edit_tat_etsi_fp_pat_error' }
        case 'tat_etsi_fp_continuity_count_error' { $iq_function_name = 'edit_tat_etsi_fp_continuity_count_error' }
        case 'tat_etsi_fp_pmt_error' { $iq_function_name = 'edit_tat_etsi_fp_pmt_error' }
        case 'tat_etsi_fp_pid_error_1' { $iq_function_name = 'edit_tat_etsi_fp_pid_error_1' }
        case 'tat_etsi_fp_pid_error_1_slider' { $iq_function_name = 'edit_tat_etsi_fp_pid_error_1_slider' }
        case 'tat_etsi_fp_pid_error_2' { $iq_function_name = 'edit_tat_etsi_fp_pid_error_2' }
        case 'tat_etsi_fp_pid_error_2_slider' { $iq_function_name = 'edit_tat_etsi_fp_pid_error_2_slider' }
        case 'tat_etsi_fp_pid_error_3' { $iq_function_name = 'edit_tat_etsi_fp_pid_error_3' }
        case 'tat_etsi_fp_pid_error_3_slider' { $iq_function_name = 'edit_tat_etsi_fp_pid_error_3_slider' }
        case 'tat_etsi_fp_pid_error_4' { $iq_function_name = 'edit_tat_etsi_fp_pid_error_4' }
        case 'tat_etsi_fp_pid_error_4_slider' { $iq_function_name = 'edit_tat_etsi_fp_pid_error_4_slider' }
        case 'tat_etsi_sp_transport_error' { $iq_function_name = 'edit_tat_etsi_sp_transport_error' }
        case 'tat_etsi_sp_crc_error' { $iq_function_name = 'edit_tat_etsi_sp_crc_error' }
        case 'tat_etsi_sp_pcr_repetition_error' { $iq_function_name = 'edit_tat_etsi_sp_pcr_repetition_error' }
        case 'tat_etsi_sp_pcr_discontinuity_error' { $iq_function_name = 'edit_tat_etsi_sp_pcr_discontinuity_error' }
        case 'tat_etsi_sp_pcr_accuracy_error' { $iq_function_name = 'edit_tat_etsi_sp_pcr_accuracy_error' }
        case 'tat_etsi_sp_pts_repetition_error' { $iq_function_name = 'edit_tat_etsi_sp_pts_repetition_error' }
        case 'tat_etsi_sp_cat_error' { $iq_function_name = 'edit_tat_etsi_sp_cat_error' }
    }

    return $iq_function_name;
}
sub start_iq {

    my $self = shift;

    my $probe_ip = $_[0];
    my $username = $_[1];
    my $password = $_[2];

    $self->{IQ} = IQ->new();

    $self->{IQ}->set_page_ip( $probe_ip );

    $self->{IQ}->start_mech();

    $self->{IQ}->login( $username, $password );
}
1;
