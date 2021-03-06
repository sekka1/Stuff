#class rfFlow
package rfFlow;
use strict;
use Data::Dumper;

#constructor for the rfFlow object
sub new {
    my ($class) = @_;
    my $self = {
        _fileName 		=> "NoFileName",
        _version 		=> "RF",
        _flowName 		=> "undef",
        _srcIP	 		=> "No",
        _dstIP	 		=> "No",
        _srcPort 		=> "No",
        _dstPort 		=> "No",
        _igmpStatus 		=> "Off",
        _alarmTemplate 		=> "tsDefault",
        _VLANTCI 		=> "No",
        _payloadTemplate   	=> "programDefault",
        _srcIPMask   		=> "255.255.255.255",
        _destIPMask	   	=> "255.255.255.255",
        _broadcast	   	=> "Yes",
        _MACforArpReply	   	=> "No",
        _channelNumber  	=> "No",
        _channelName       	=> "No",
        _channelAlias       	=> "No",
        _deviceRef       	=> "No",
        _channelOffPeriod      	=> "No",
        _channelOffAirTemplate 	=> "No",
        _RTP_SSRC 		=> "No",
        _rfChannel	 	=> "RFChannel"
    };
    bless $self, $class;
    return $self;
}


#accessor method for program fileName
sub fileName {
    my ( $self, $fileName ) = @_;
    $self->{_fileName} = $fileName if defined($fileName);
    return $self->{_fileName};
}
#accessor method for program version
sub version {
    my ( $self, $version ) = @_;
    $self->{_version} = $version if defined($version);
    return $self->{_version};
}

#accessor method for program flowName
sub flowName {
    my ( $self, $flowName ) = @_;
    $self->{_flowName} = $flowName if defined($flowName);
    return $self->{_flowName};
}

#accessor method for program srcIP
sub srcIP {
    my ( $self, $srcIP ) = @_;
    $self->{_srcIP} = $srcIP if defined($srcIP);
    return $self->{_srcIP};
}

#accessor method for program dstIP
sub dstIP {
    my ( $self, $dstIP ) = @_;
    $self->{_dstIP} = $dstIP if defined($dstIP);
    return $self->{_dstIP};
}

#accessor method for program srcPort
sub srcPort {
    my ( $self, $srcPort ) = @_;
    $self->{_srcPort} = $srcPort if defined($srcPort);
    return $self->{_srcPort};
}

#accessor method for program dstPort
sub dstPort {
    my ( $self, $dstPort ) = @_;
    $self->{_dstPort} = $dstPort if defined($dstPort);
    return $self->{_dstPort};
}

#accessor method for program igmpStatus
sub igmpStatus {
    my ( $self, $igmpStatus ) = @_;
    $self->{_igmpStatus} = $igmpStatus if defined($igmpStatus);
    return $self->{_igmpStatus};
}

#accessor method for program alarmTemplate
sub alarmTemplate {
    my ( $self, $alarmTemplate ) = @_;
    $self->{_alarmTemplate} = $alarmTemplate if defined($alarmTemplate);
    return $self->{_alarmTemplate};
}

#accessor method for program VLANTCI
sub VLANTCI {
    my ( $self, $VLANTCI ) = @_;
    $self->{_VLANTCI} = $VLANTCI if defined($VLANTCI);
    return $self->{_VLANTCI};
}

#accessor method for program  payloadTemplate
sub payloadTemplate {
    my ( $self, $payloadTemplate ) = @_;
    $self->{_payloadTemplate} = $payloadTemplate if defined($payloadTemplate);
    return $self->{_payloadTemplate};
}

#accessor method for program  srcIPMask
sub srcIPMask {
    my ( $self, $srcIPMask ) = @_;
    $self->{_srcIPMask} = $srcIPMask if defined($srcIPMask);
    return $self->{_srcIPMask};
}

#accessor method for program  destIPMask
sub destIPMask {
    my ( $self, $destIPMask ) = @_;
    $self->{_destIPMask} = $destIPMask if defined($destIPMask);
    return $self->{_destIPMask};
}

#accessor method for program  broadcast
sub broadcast {
    my ( $self, $broadcast ) = @_;
    $self->{_broadcast} = $broadcast if defined($broadcast);
    return $self->{_broadcast};
}

#accessor method for program  MACforArpReply
sub MACforArpReply {
    my ( $self, $MACforArpReply ) = @_;
    $self->{_MACforArpReply} = $MACforArpReply if defined($MACforArpReply);
    return $self->{_MACforArpReply};
}

#accessor method for program  channelNumber
sub channelNumber {
    my ( $self, $channelNumber ) = @_;
    $self->{_channelNumber} = $channelNumber if defined($channelNumber);
    return $self->{_channelNumber};
}

#accessor method for program  channelName
sub channelName {
    my ( $self, $channelName ) = @_;
    $self->{_channelName} = $channelName if defined($channelName);
    return $self->{_channelName};
}

#accessor method for program  channelAlias
sub channelAlias {
    my ( $self, $channelAlias ) = @_;
    $self->{_channelAlias} = $channelAlias if defined($channelAlias);
    return $self->{_channelAlias};
}

#accessor method for program  deviceRef
sub deviceRef {
    my ( $self, $deviceRef ) = @_;
    $self->{_deviceRef} = $deviceRef if defined($deviceRef);
    return $self->{_deviceRef};
}

#accessor method for program  channelOffPeriod
sub channelOffPeriod {
    my ( $self, $channelOffPeriod ) = @_;
    $self->{_channelOffPeriod} = $channelOffPeriod if defined($channelOffPeriod);
    return $self->{_channelOffPeriod};
}

#accessor method for program  channelOffAirTemplate
sub channelOffAirTemplate {
    my ( $self, $channelOffAirTemplate ) = @_;
    $self->{_channelOffAirTemplate} = $channelOffAirTemplate if defined($channelOffAirTemplate);
    return $self->{_channelOffAirTemplate};
}

#accessor method for program  RTP_SSRC
sub RTP_SSRC {
    my ( $self, $RTP_SSRC ) = @_;
    $self->{_RTP_SSRC} = $RTP_SSRC if defined($RTP_SSRC);
    return $self->{_RTP_SSRC};
}

#accessor method for program  rfChannel
sub rfChannel {
    my ( $self, $rfChannel ) = @_;
    $self->{_rfChannel} = $rfChannel if defined($rfChannel);
    return $self->{_rfChannel};
}

sub printHeader{
#	print Dumper(@_);

# Shift off the object and get the fileNsme
	shift;
	# shift all class ds
   	my $fileName = shift;

open (FILE, ">", $fileName) or die "Cannot Open Dest File $!\n";
                        print FILE "version(J)\t name(1)\tsourceIp(2)\tdestIp(3)\tsrcPort(4)\tdestPort(5)\tigmpStatus(6)\talarmTemplate(7)\tVLANTCI(8)\tpayloadTemplate(9)\tsrcIpMask(10)\tdestIpMask(11) \tBroadcast(12)\tMACforARPReply(13)\tchannelNumber(15)\tchannelName(14)\tchannelAliasNumber(18)\tdeviceRef(22)\tchannelOffPeriod(32)\tchannelOffAirTemplate(33)\tRTP SSRC(35)\tRF channel(21)\n";
close FILE;
}


sub printFlows {
    my ($self) = @_;
    open (FILE, ">>", $self->fileName) or die "Cannot open $!\n";
    #print RF Channel info
    print FILE $self->version,"\t",  
    $self->flowName,"\t", 
    $self->srcIP,"\t", 
    $self->dstIP,"\t", 
    $self->srcPort,"\t", 
    $self->dstPort,"\t", 
    $self->igmpStatus,"\t", 
    $self->alarmTemplate,"\t", 
    $self->VLANTCI,"\t", 
    $self->payloadTemplate,"\t", 
    $self->srcIPMask,"\t", 
    $self->destIPMask,"\t", 
    $self->broadcast,"\t", 
    $self->MACforArpReply,"\t", 
    $self->channelNumber,"\t",
    $self->channelName,"\t",
    $self->channelAlias,"\t",
    $self->deviceRef,"\t",
    $self->channelOffPeriod,"\t",
    $self->channelOffAirTemplate,"\t",
    $self->RTP_SSRC,"\t",
    $self->rfChannel,"\n";
    close FILE;
}

1;

