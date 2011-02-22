#!/usr/bin/perl
use strict;
use Data::Dumper;
$Data::Dumper::Indent = 1;
use Spreadsheet::Read;
use ipFlow;
use program;
my $numProbes = 0;
my $numFlows = 0;
my $numPrograms = 0;
my $ref = ReadData ("Source/Regional Source Sheet 10-04-2010-ver1.xls");
my $destIP_Dir = "IQAlias/ip/";              ## Output Alias file Directory
my $emptyLine = 0;
my %probes;
my %allFlows;				
my %allMonFlows;				
my %allMPTSmpeg4Flows;				
my %allMPTSmpeg2Flows;				
my @allPrograms;               		## array to hold all program objects 
my @allMPTSPrograms;               	## array to hold all program objects 
my @allSPTSPrograms;               	## array to hold all program objects 

#Dump out all the sheets that it read in
#print Dumper($ref->[0]{sheet});

# Print out the first sheet cell A8
print "xxxx: " . $ref->[1]{'A8'} . "\n\n";


opendir(DIR, "$destIP_Dir"); #read IP Dir
my @files = readdir(DIR);
foreach my $file (@files) {
	if ( $file eq "." || $file eq ".." ) {next } { # ignore dir struct
		if (unlink ($destIP_Dir.$file) != 0) { } else {print "Warning: $destIP_Dir.$file NOT Cleaned!\n"; }}
}

my $sheet = 4;

### Begin HD LCF Collection >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
for ( my $line = 1; $emptyLine < 10; $line++) {
	my $testLine = "U".$line;
	my $testEmptyLine = "U".$line;
	my $testEmptyMPEG = "G".$line;
	if ($ref->[$sheet]{$testEmptyLine} eq ""){
		$emptyLine++;
	}
	if  (
		($ref->[$sheet]{$testLine} ne undef) 
		&& 
		($ref->[$sheet]{$testLine} ne "ProbeName") 
		&& 
		($ref->[$sheet]{$testEmptyMPEG} ne undef)
		){
		$emptyLine = 0;
		my $probeNameCol  = "U".$line;
		my $stationNameCol = "D".$line;
		my $programNameCol = "E".$line;
		my $srcSPTSIPCol = "N".$line;
		my $dstSPTSIPCol = "O".$line;
		my $srcBackupIPCol = "Q".$line;
		my $dstBackupIPCol = "R".$line;
		my $dstSPTSUDPPortCol = "P".$line;
		my $mpegSPTSNumberCol = "G".$line;
		my $auxMuxNameCol = "B".$line;
		my $uplinkNameCol = "V".$line;
		my $transportAlarmTemplateCol = "W".$line;
		my $programAlarmTemplateCol = "X".$line;
		my $probeName= $ref->[$sheet]{$probeNameCol};
		my $programName= $ref->[$sheet]{$programNameCol};
		my $stationName= $ref->[$sheet]{$stationNameCol};
		my $srcSPTSIP = $ref->[$sheet]{$srcSPTSIPCol};
		my $dstSPTSIP = $ref->[$sheet]{$dstSPTSIPCol};
		my $srcBackupIP = $ref->[$sheet]{$srcBackupIPCol};
		my $dstBackupIP = $ref->[$sheet]{$dstBackupIPCol};
		my $dstSPTSUDPPort = "$ref->[$sheet]{$dstSPTSUDPPortCol}";
		my $mpegSPTSNumber = $ref->[$sheet]{$mpegSPTSNumberCol};
		my $auxMuxName = "$ref->[$sheet]{$auxMuxNameCol}";
		my $uplinkName = $ref->[$sheet]{$uplinkNameCol};
		my $transportAlarmTemplate = $ref->[$sheet]{$transportAlarmTemplateCol};
		my $programAlarmTemplate = $ref->[$sheet]{$programAlarmTemplateCol};
		my $flowName = $stationName."_".$programName;
		my $deviceRef = $probeName." ".$ref->[$sheet]{$stationNameCol};
		my $primaryFlowName = $probeName."_".$flowName."-p";
		my $backupFlowName = $probeName."_".$flowName."-b";
		my $primaryUplinkFlowName = "U_".$primaryFlowName;
		my $backupUplinkFlowName = "U_".$backupFlowName;
		my $igmpSets = "1";
		my $ports = "3";
		SWITCH:{
			(($auxMuxName =~ "QC") or ($auxMuxName=~ "Iplex")) && do{
				my $fileName = $destIP_Dir.$probeName.".xls";
                                my $monFlowName = $probeName."_".$auxMuxName;
                                my $flowControlName = $probeName.$monFlowName;
                                my $LCF_MonFlow = eval { new ipFlow(); } or die ($@);
                                $LCF_MonFlow->fileName($fileName);
                                $LCF_MonFlow->flowName($monFlowName);
                                $LCF_MonFlow->srcIP($srcSPTSIP);
                                $LCF_MonFlow->dstIP($dstSPTSIP);
                                $LCF_MonFlow->dstPort($dstSPTSUDPPort);
                                $LCF_MonFlow->broadcast('4');
                                $LCF_MonFlow->igmpSets($igmpSets);
                                $LCF_MonFlow->ports($ports);
				if ($transportAlarmTemplate ne undef){
					$LCF_MonFlow->alarmTemplate($transportAlarmTemplate);
				}
                                $allFlows{$flowControlName} = $LCF_MonFlow;
                        next SWITCH; };
				

			($probeName ne undef) && do {
				$probes{$probeName} = $probeName;
				$probes{$uplinkName} = $uplinkName;
				my $fileName = $destIP_Dir.$probeName.".xls";
				my $uplink1FileName = $destIP_Dir.$uplinkName.".xls";

				#Create flow class instance
				my $LCFPrimaryFlow = eval { new ipFlow(); } or die ($@);
				my $LCFBackupFlow = eval { new ipFlow(); } or die ($@);
				my $LCFUplinkPrimaryFlow = eval { new ipFlow(); } or die ($@);
				my $LCFUplinkBackupFlow = eval { new ipFlow(); } or die ($@);
			
				$LCFPrimaryFlow->fileName($fileName);
				$LCFBackupFlow->fileName($fileName);
				$LCFUplinkPrimaryFlow->fileName($uplink1FileName);
				$LCFUplinkBackupFlow->fileName($uplink1FileName);
				$LCFPrimaryFlow->flowName($primaryFlowName);
				$LCFBackupFlow->flowName($backupFlowName);
				$LCFUplinkPrimaryFlow->flowName($primaryUplinkFlowName);
				$LCFUplinkBackupFlow->flowName($backupUplinkFlowName);
				$LCFPrimaryFlow->dstIP($dstSPTSIP);
				$LCFPrimaryFlow->srcIP($srcSPTSIP);
				$LCFUplinkPrimaryFlow->dstIP($dstSPTSIP);
				$LCFUplinkPrimaryFlow->srcIP($srcSPTSIP);
				$LCFBackupFlow->srcIP($srcBackupIP);
				$LCFBackupFlow->dstIP($dstBackupIP);
				$LCFUplinkBackupFlow->srcIP($srcBackupIP);
				$LCFUplinkBackupFlow->dstIP($dstBackupIP);
				$LCFPrimaryFlow->dstPort($dstSPTSUDPPort);
				$LCFBackupFlow->dstPort($dstSPTSUDPPort);
				$LCFUplinkPrimaryFlow->dstPort($dstSPTSUDPPort);
				$LCFUplinkBackupFlow->dstPort($dstSPTSUDPPort);
				$LCFPrimaryFlow->igmpSets($igmpSets);
				$LCFBackupFlow->igmpSets($igmpSets);
				$LCFUplinkPrimaryFlow->igmpSets($igmpSets);
				$LCFUplinkBackupFlow->igmpSets($igmpSets);
				$LCFPrimaryFlow->ports($ports);
				$LCFBackupFlow->ports($ports);
				$LCFUplinkPrimaryFlow->ports($ports);
				$LCFUplinkBackupFlow->ports($ports);
				if ($transportAlarmTemplate ne undef){
				$LCFPrimaryFlow->alarmTemplate($transportAlarmTemplate);
				$LCFBackupFlow->alarmTemplate($transportAlarmTemplate);
				$LCFUplinkPrimaryFlow->alarmTemplate($transportAlarmTemplate);
				$LCFUplinkBackupFlow->alarmTemplate($transportAlarmTemplate);
				}
		
				$allFlows{$primaryFlowName} = $LCFPrimaryFlow;	
				$allFlows{$backupFlowName} = $LCFBackupFlow;
				$allFlows{$primaryUplinkFlowName} = $LCFUplinkPrimaryFlow;
				$allFlows{$backupUplinkFlowName} = $LCFUplinkBackupFlow;

#######################################################################
## Instantiate the HD LCF program object                            ##
#####################################################################
				#Create program class instance
				my $LCFPrimaryProgram = eval { new program(); } or die ($@);
				my $LCFBackupProgram = eval { new program(); } or die ($@);
				my $LCFPrimaryUplinkProgram = eval { new program(); } or die ($@);
				my $LCFBackupUplinkProgram = eval { new program(); } or die ($@);
						
				$LCFPrimaryProgram->fileName($fileName);
				$LCFBackupProgram->fileName($fileName);
				$LCFPrimaryUplinkProgram->fileName($uplink1FileName);
				$LCFBackupUplinkProgram->fileName($uplink1FileName);
				$LCFPrimaryProgram->flowName($primaryFlowName);
				$LCFBackupProgram->flowName($backupFlowName);
				$LCFPrimaryUplinkProgram->flowName($primaryUplinkFlowName);
				$LCFBackupUplinkProgram->flowName($backupUplinkFlowName);
				$LCFPrimaryProgram->channelNumber($mpegSPTSNumber);
				$LCFBackupProgram->channelNumber($mpegSPTSNumber);
				$LCFPrimaryUplinkProgram->channelNumber($mpegSPTSNumber);
				$LCFBackupUplinkProgram->channelNumber($mpegSPTSNumber);
				$LCFPrimaryProgram->channelName($programName);
				$LCFBackupProgram->channelName($programName);
				$LCFPrimaryUplinkProgram->channelName($programName);
				$LCFBackupUplinkProgram->channelName($programName);
				if ($programAlarmTemplate ne undef){
				$LCFPrimaryProgram->payloadTemplate($programAlarmTemplate);
				$LCFBackupProgram->payloadTemplate($programAlarmTemplate);
				$LCFPrimaryUplinkProgram->payloadTemplate($programAlarmTemplate);
				$LCFBackupUplinkProgram->payloadTemplate($programAlarmTemplate);
				}

				push @allPrograms, $LCFPrimaryProgram;
				push @allPrograms, $LCFBackupProgram;
				push @allPrograms, $LCFPrimaryUplinkProgram;
				push @allPrograms, $LCFBackupUplinkProgram;
			};
		}


	}
}
## End Data collection HD IP LCF - 10.192 ---------->
$sheet = 6;
### Begin Data collection WB2 - 10.193 ------------->
$emptyLine = 0;
for ( my $line = 1; $emptyLine < 10; $line++) {
	my $testLine = "A".$line;
	my $testEmptyLine = "W".$line;
	my $testEmptyMPEG = "H".$line;
	my $stationNameCol = "E".$line;
	if ($ref->[5]{$testEmptyLine} eq ""){
		$emptyLine++;
	}
	if  (
		($ref->[$sheet]{$testLine} gt 0)
		and 
		($ref->[$sheet]{$testEmptyLine} ne "Probe")
		#and
		#($ref->[$sheet]{$testLine} !~ "MUX")
		)
	{
		$emptyLine = 0;
		my $videoFormat;
		my $probeNameCol  = "W".$line;
		my $programNameCol  = "F".$line;
		my $stationNameCol  = "E".$line;
		my $srcSPTSIPCol = "R".$line;
		my $dstSPTSIPCol = "T".$line;
		my $dstSPTSUDPPortCol = "V".$line;
		my $mpegSPTSNumberCol = "H".$line;
		my $mpegMPTSNumberCol = "A".$line;
		my $uplink_1_NameCol = "X".$line;
		my $uplink_2_NameCol = "Y".$line;
		my $alarmTemplateCol = "Z".$line;
		my $payloadTemplateCol = "AA".$line;
		my $probeName = $ref->[$sheet]{$probeNameCol};
		my $programName = $ref->[$sheet]{$programNameCol};
		my $stationName = $ref->[$sheet]{$stationNameCol};
		my $srcSPTSIP = $ref->[$sheet]{$srcSPTSIPCol};
		my $dstSPTSIP = $ref->[$sheet]{$dstSPTSIPCol};
		my $dstSPTSUDPPort = $ref->[$sheet]{$dstSPTSUDPPortCol};
		my $mpegSPTSNumber = $ref->[$sheet]{$mpegSPTSNumberCol};
		my $mpegMPTSNumber = $ref->[$sheet]{$mpegMPTSNumberCol};
		my $uplink_1_Name = $ref->[$sheet]{$uplink_1_NameCol};
		my $uplink_2_Name = $ref->[$sheet]{$uplink_2_NameCol};
		my $alarmTemplate = $ref->[$sheet]{$alarmTemplateCol};
		my $payloadTemplate = $ref->[$sheet]{$payloadTemplateCol};
		my $deviceRef = $probeName." ".$ref->[$sheet]{$stationNameCol};
		my $SPTSFlowName = $probeName."_".$programName;
		my $SPTSProgramName = $probeName."_".$programName;
		my $MPTSFlowName = $probeName."_MPTS";
		my $igmpSets = '1';
		my $ports = '3';
       		SWITCH:{
			( ($mpegMPTSNumber =~ "BU Encoder")|| ($mpegMPTSNumber =~ "Mon Encoder")|| ($mpegMPTSNumber =~ "RX QC")
			) && do {
				my $fileName = $destIP_Dir.$probeName.".xls";
				my $monFlowName = $probeName."_".$mpegMPTSNumber;
				my $flowControlName = $probeName.$monFlowName;
				my $WB_2_MonFlow = eval { new ipFlow(); } or die ($@);
				$WB_2_MonFlow->fileName($fileName);
				$WB_2_MonFlow->flowName($monFlowName);
				$WB_2_MonFlow->srcIP($srcSPTSIP);
				$WB_2_MonFlow->dstIP($dstSPTSIP);
				$WB_2_MonFlow->dstPort($dstSPTSUDPPort);
				$WB_2_MonFlow->igmpSets($igmpSets);
				$WB_2_MonFlow->ports($ports);
				if ($alarmTemplate ne ''){
				$WB_2_MonFlow->alarmTemplate($alarmTemplate);
				}
				$allFlows{$flowControlName} = $WB_2_MonFlow;
			next SWITCH; };
			(
			($mpegMPTSNumber =~ 'MUX MPEG4')
			and
			($probeName gt "")
			)&& do {
				my $fileName = $destIP_Dir.$probeName.".xls";
				my $uplink1FileName = $destIP_Dir.$uplink_1_Name.".xls";
				my $uplink2FileName = $destIP_Dir.$uplink_2_Name.".xls";
				my $flowName = $probeName."_MPTS_mpeg4";
				my $flowControlName = $probeName."_MPTS_mpeg4";
				my $uplink1FlowControlName = $probeName."_MPTS_mpeg4-UL1";
				my $uplink2FlowControlName = $probeName."_MPTS_mpeg4-UL2";
				my $WB_2_MPTSmpeg4Flow = eval { new ipFlow(); } or die ($@);
				my $WB_2_MPTSmpeg4Uplink1Flow = eval { new ipFlow(); } or die ($@);
				my $WB_2_MPTSmpeg4Uplink2Flow = eval { new ipFlow(); } or die ($@);
				$WB_2_MPTSmpeg4Flow->fileName($fileName);
				$WB_2_MPTSmpeg4Flow->flowName($flowName);
				$WB_2_MPTSmpeg4Flow->srcIP($srcSPTSIP);
				$WB_2_MPTSmpeg4Flow->dstIP($dstSPTSIP);
				$WB_2_MPTSmpeg4Flow->dstPort($dstSPTSUDPPort);
				$WB_2_MPTSmpeg4Flow->igmpSets($igmpSets);
				$WB_2_MPTSmpeg4Flow->ports($ports);
				if ($alarmTemplate ne ''){
					$WB_2_MPTSmpeg4Flow->alarmTemplate($alarmTemplate);
				}	
				$allFlows{$flowControlName} = $WB_2_MPTSmpeg4Flow;
				foreach my $mptsProgram (@allMPTSPrograms){
					if ($mptsProgram->flowName =~ $probeName){
						my $mptsMPEG4Program = eval { new program(); } or die ($@);
						$mptsMPEG4Program->fileName($fileName);
						$mptsMPEG4Program->flowName($mptsProgram->flowName()."_mpeg4");
						$mptsMPEG4Program->channelName($mptsProgram->channelName()."_mpeg4");
						$mptsMPEG4Program->channelNumber($mptsProgram->channelNumber());
						$mptsMPEG4Program->alarmTemplate($mptsProgram->alarmTemplate());
						$mptsMPEG4Program->payloadTemplate($mptsProgram->payloadTemplate());
						push @allPrograms, $mptsMPEG4Program;
						}
				}
				foreach my $sptsProgram (@allSPTSPrograms){
					if ($sptsProgram->flowName =~ $probeName){
						my $sptsMPEG4Program = eval { new program(); } or die ($@);
						$sptsMPEG4Program->fileName($fileName);
						$sptsMPEG4Program->flowName($sptsProgram->flowName());
						$sptsMPEG4Program->channelName($sptsProgram->channelName()."_mpeg4");
						$sptsMPEG4Program->channelNumber($sptsProgram->channelNumber());
						$sptsMPEG4Program->alarmTemplate($sptsProgram->alarmTemplate());
						$sptsMPEG4Program->payloadTemplate($sptsProgram->payloadTemplate());
						push @allPrograms, $sptsMPEG4Program;
						}
					}
				SWITCH:{
					($uplink_1_Name ne '') && do {
					$WB_2_MPTSmpeg4Uplink1Flow->fileName($uplink1FileName);
					$WB_2_MPTSmpeg4Uplink1Flow->flowName($flowName);
					$WB_2_MPTSmpeg4Uplink1Flow->srcIP($srcSPTSIP);
					$WB_2_MPTSmpeg4Uplink1Flow->dstIP($dstSPTSIP);
					$WB_2_MPTSmpeg4Uplink1Flow->dstPort($dstSPTSUDPPort);
					$WB_2_MPTSmpeg4Uplink1Flow->igmpSets($igmpSets);
					$WB_2_MPTSmpeg4Uplink1Flow->ports($ports);
					if ($alarmTemplate ne undef){
						$WB_2_MPTSmpeg4Uplink1Flow->alarmTemplate($alarmTemplate);
					}	
					$allFlows{$uplink1FlowControlName} = $WB_2_MPTSmpeg4Uplink1Flow;
					foreach my $mptsProgram (@allMPTSPrograms){
						if ($mptsProgram->flowName =~ $probeName){
							my $mptsMPEG4Program = eval { new program(); } or die ($@);
							$mptsMPEG4Program->fileName($uplink1FileName);
							$mptsMPEG4Program->flowName($mptsProgram->flowName()."_mpeg4");
							$mptsMPEG4Program->channelName($mptsProgram->channelName()."_mpeg4");
							$mptsMPEG4Program->channelNumber($mptsProgram->channelNumber());
							$mptsMPEG4Program->alarmTemplate($mptsProgram->alarmTemplate());
							$mptsMPEG4Program->payloadTemplate($mptsProgram->payloadTemplate());
							push @allPrograms, $mptsMPEG4Program;
							}
					}
					 };
					($uplink_2_Name ne '') && do {
					$WB_2_MPTSmpeg4Uplink2Flow->fileName($uplink2FileName);
					$WB_2_MPTSmpeg4Uplink2Flow->flowName($flowName);
					$WB_2_MPTSmpeg4Uplink2Flow->srcIP($srcSPTSIP);
					$WB_2_MPTSmpeg4Uplink2Flow->dstIP($dstSPTSIP);
					$WB_2_MPTSmpeg4Uplink2Flow->dstPort($dstSPTSUDPPort);
					$WB_2_MPTSmpeg4Uplink2Flow->igmpSets($igmpSets);
					$WB_2_MPTSmpeg4Uplink2Flow->ports($ports);
					if ($alarmTemplate ne undef){
						$WB_2_MPTSmpeg4Uplink2Flow->alarmTemplate($alarmTemplate);
					}	
					$allFlows{$uplink2FlowControlName} = $WB_2_MPTSmpeg4Uplink2Flow;
					foreach my $mptsProgram (@allMPTSPrograms){
						if ($mptsProgram->flowName =~ $probeName){
							my $mptsMPEG4Program = eval { new program(); } or die ($@);
							$mptsMPEG4Program->fileName($uplink2FileName);
							$mptsMPEG4Program->flowName($mptsProgram->flowName()."_mpeg4");
							$mptsMPEG4Program->channelName($mptsProgram->channelName()."_mpeg4");
							$mptsMPEG4Program->channelNumber($mptsProgram->channelNumber());
							$mptsMPEG4Program->alarmTemplate($mptsProgram->alarmTemplate());
							$mptsMPEG4Program->payloadTemplate($mptsProgram->payloadTemplate());
							push @allPrograms, $mptsMPEG4Program;
							}
					}
				 };
			}
			next SWITCH; };
			(
			($mpegMPTSNumber =~ 'MUX MPEG2')
			and
			($probeName gt "")
			)&& do {
				my $fileName = $destIP_Dir.$probeName.".xls";
				my $uplink1FileName = $destIP_Dir.$uplink_1_Name.".xls";
				my $uplink2FileName = $destIP_Dir.$uplink_2_Name.".xls";
				my $flowName = $probeName."_MPTS_mpeg2";
				my $flowControlName = $probeName."_MPTS_mpeg2";
				my $uplink1FlowControlName = $probeName."_MPTS_mpeg2-UL1";
				my $uplink2FlowControlName = $probeName."_MPTS_mpeg2-UL2";
				my $WB_2_MPTSmpeg2Flow = eval { new ipFlow(); } or die ($@);
				my $WB_2_MPTSmpeg2Uplink1Flow = eval { new ipFlow(); } or die ($@);
				my $WB_2_MPTSmpeg2Uplink2Flow = eval { new ipFlow(); } or die ($@);
				$WB_2_MPTSmpeg2Flow->fileName($fileName);
				$WB_2_MPTSmpeg2Flow->flowName($flowName);
				$WB_2_MPTSmpeg2Flow->srcIP($srcSPTSIP);
				$WB_2_MPTSmpeg2Flow->dstIP($dstSPTSIP);
				$WB_2_MPTSmpeg2Flow->dstPort($dstSPTSUDPPort);
				$WB_2_MPTSmpeg2Flow->igmpSets($igmpSets);
				$WB_2_MPTSmpeg2Flow->ports($ports);
				if ($alarmTemplate ne ''){
					$WB_2_MPTSmpeg2Flow->alarmTemplate($alarmTemplate);
				}	
				$allFlows{$flowControlName} = $WB_2_MPTSmpeg2Flow;
				foreach my $mptsProgram (@allMPTSPrograms){
					if ($mptsProgram->flowName =~ $probeName){
						my $mptsMPEG2Program = eval { new program(); } or die ($@);
						$mptsMPEG2Program->fileName($fileName);
						$mptsMPEG2Program->flowName($mptsProgram->flowName()."_mpeg2");
						$mptsMPEG2Program->channelName($mptsProgram->channelName()."_mpeg2");
						$mptsMPEG2Program->channelNumber("4".$mptsProgram->channelNumber());
						$mptsMPEG2Program->alarmTemplate($mptsProgram->alarmTemplate());
						$mptsMPEG2Program->payloadTemplate($mptsProgram->payloadTemplate());
						push @allPrograms, $mptsMPEG2Program;
						}
				}
				foreach my $sptsProgram (@allSPTSPrograms){
					if ($sptsProgram->flowName =~ $probeName){
						my $sptsMPEG2Program = eval { new program(); } or die ($@);
						$sptsMPEG2Program->fileName($fileName);
						$sptsMPEG2Program->flowName($sptsProgram->flowName());
						$sptsMPEG2Program->channelName($sptsProgram->channelName()."_mpeg2");
						$sptsMPEG2Program->channelNumber("4".$sptsProgram->channelNumber());
						$sptsMPEG2Program->alarmTemplate($sptsProgram->alarmTemplate());
						$sptsMPEG2Program->payloadTemplate($sptsProgram->payloadTemplate());
						push @allPrograms, $sptsMPEG2Program;
						}
					}
				SWITCH:{
					($uplink_1_Name ne '') && do {
					$WB_2_MPTSmpeg2Uplink1Flow->fileName($uplink1FileName);
					$WB_2_MPTSmpeg2Uplink1Flow->flowName($flowName);
					$WB_2_MPTSmpeg2Uplink1Flow->srcIP($srcSPTSIP);
					$WB_2_MPTSmpeg2Uplink1Flow->dstIP($dstSPTSIP);
					$WB_2_MPTSmpeg2Uplink1Flow->dstPort($dstSPTSUDPPort);
					$WB_2_MPTSmpeg2Uplink1Flow->igmpSets($igmpSets);
					$WB_2_MPTSmpeg2Uplink1Flow->ports($ports);
					if ($alarmTemplate ne undef){
						$WB_2_MPTSmpeg2Uplink1Flow->alarmTemplate($alarmTemplate);
					}	
					$allFlows{$uplink1FlowControlName} = $WB_2_MPTSmpeg2Uplink1Flow;
					foreach my $mptsProgram (@allMPTSPrograms){
						if ($mptsProgram->flowName =~ $probeName){
							my $mptsMPEG2Program = eval { new program(); } or die ($@);
							$mptsMPEG2Program->fileName($uplink1FileName);
							$mptsMPEG2Program->flowName($mptsProgram->flowName()."_mpeg2");
							$mptsMPEG2Program->channelName($mptsProgram->channelName()."_mpeg2");
							$mptsMPEG2Program->channelNumber("4".$mptsProgram->channelNumber());
							$mptsMPEG2Program->alarmTemplate($mptsProgram->alarmTemplate());
							$mptsMPEG2Program->payloadTemplate($mptsProgram->payloadTemplate());
							push @allPrograms, $mptsMPEG2Program;
							}
					}
					 };
					($uplink_2_Name ne '') && do {
					$WB_2_MPTSmpeg2Uplink2Flow->fileName($uplink2FileName);
					$WB_2_MPTSmpeg2Uplink2Flow->flowName($flowName);
					$WB_2_MPTSmpeg2Uplink2Flow->srcIP($srcSPTSIP);
					$WB_2_MPTSmpeg2Uplink2Flow->dstIP($dstSPTSIP);
					$WB_2_MPTSmpeg2Uplink2Flow->dstPort($dstSPTSUDPPort);
					$WB_2_MPTSmpeg2Uplink2Flow->igmpSets($igmpSets);
					$WB_2_MPTSmpeg2Uplink2Flow->ports($ports);
					if ($alarmTemplate ne undef){
						$WB_2_MPTSmpeg2Uplink2Flow->alarmTemplate($alarmTemplate);
					}	
					$allFlows{$uplink2FlowControlName} = $WB_2_MPTSmpeg2Uplink2Flow;
					foreach my $mptsProgram (@allMPTSPrograms){
						if ($mptsProgram->flowName =~ $probeName){
							my $mptsMPEG2Program = eval { new program(); } or die ($@);
							$mptsMPEG2Program->fileName($uplink2FileName);
							$mptsMPEG2Program->flowName($mptsProgram->flowName()."_mpeg2");
							$mptsMPEG2Program->channelName($mptsProgram->channelName()."_mpeg2");
							$mptsMPEG2Program->channelNumber("4".$mptsProgram->channelNumber());
							$mptsMPEG2Program->alarmTemplate($mptsProgram->alarmTemplate());
							$mptsMPEG2Program->payloadTemplate($mptsProgram->payloadTemplate());
							push @allPrograms, $mptsMPEG2Program;
							}
					}
				 };
			}
			next SWITCH; };
                       
                       
		       ($probeName ne undef ) && do {
			$probes{$probeName} = $probeName;
			my $fileName = $destIP_Dir.$probeName.".xls";
			my $SPTSFlowControlName = $probeName.$SPTSFlowName;
			my $WB_2_SPTSFlow = eval { new ipFlow(); } or die ($@);
			my $WB_2_SPTSProgram = eval { new program(); } or die ($@);
			my $WB_2_MPTSProgram = eval { new program(); } or die ($@);
			
			$WB_2_SPTSFlow->fileName($fileName);
			$WB_2_SPTSFlow->flowName($SPTSFlowName);
			$WB_2_SPTSFlow->srcIP($srcSPTSIP);
			$WB_2_SPTSFlow->dstIP($dstSPTSIP);
			$WB_2_SPTSFlow->dstPort($dstSPTSUDPPort);
			$WB_2_SPTSFlow->igmpSets($igmpSets);
			$WB_2_SPTSFlow->ports($ports);
			if ($alarmTemplate ne undef){
			$WB_2_SPTSFlow->alarmTemplate($alarmTemplate);
			}
			
			$allFlows{$SPTSFlowControlName} = $WB_2_SPTSFlow;
				
			$WB_2_SPTSProgram->fileName($fileName);
			$WB_2_MPTSProgram->fileName($fileName);
			$WB_2_SPTSProgram->flowName($SPTSFlowName);
			$WB_2_MPTSProgram->flowName($MPTSFlowName);
			$WB_2_SPTSProgram->channelNumber($mpegSPTSNumber);
			$WB_2_MPTSProgram->channelNumber($mpegMPTSNumber);
			$WB_2_SPTSProgram->channelName($programName);
			$WB_2_MPTSProgram->channelName($programName);
			if ($payloadTemplate ne ""){
			$WB_2_SPTSProgram->payloadTemplate($payloadTemplate);
			$WB_2_MPTSProgram->payloadTemplate($payloadTemplate);
			}

			push @allSPTSPrograms, $WB_2_SPTSProgram;
			push @allMPTSPrograms, $WB_2_MPTSProgram;

                        }; 

                      }

		



	}
}
#print Dumper(%allFlows);
#>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>  Create Alias Files >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
foreach my $probe (keys %probes) {
	##print "Probe $probe\n";
	next unless ($probe gt undef);
	next if ($probe eq  " ");
	my $fileName;
	$numProbes++;
	my $ipAliasFile = eval { new ipFlow(); } or die ($@);
	$fileName = $destIP_Dir.$probe.".xls";
	$ipAliasFile->printHeader($fileName);
}
%probes = ();
print "$numProbes Probe file headers created  :-)\n";
#>>>>>>>>>>Print the Flows >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
# Call print flows function from the flows module
 
	print "\nFlows = ";
	foreach my $flow (values %allFlows){#
		$numFlows++;
		#print ".";
		$flow->printFlows();
	}
	print "$numFlows\n";
	%allFlows = (); 
	$numFlows = 0;


#>>>>>>>>Print the Programs >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
# Call the print programs function from the program module 
	print "\n Programs = ";
	foreach my $newProgram (@allPrograms){
		$numPrograms++;
		#print ".";
		$newProgram->printPrograms();
	}
	print "$numPrograms\n";
	@allPrograms = ();
	$numPrograms = 0;
		
	print "\nAlias Creation Successfully  Done!\n\n";
