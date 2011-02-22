#!/usr/bin/perl

#
# This script generates the alias files for the Columbia area
# Criteria: Global, HOTG SC, Columbia tab
#

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
my %probes;
my %allFlows;						## Hash to hold all flow objects
my @allPrograms;               		## array to hold all program objects 

# Other Default Vars
my $probe = 'Charlotte';                # Name of the ouput file
my $output_filename = $probe.'.xls';
my $igmpSets = "1";
my $ports = "3";
my $broadcast = "4";
my $transportAlarmTemplate = 'Standard Transport at IP';
my $programAlarmTemplate = 'Standard Video Service at IP';

#Dump out all the sheets that it read in
#print Dumper($ref->[0]{sheet});

# Delete old alias files from the output directory before going on
#opendir(DIR, "$destIP_Dir"); #read IP Dir
#my @files = readdir(DIR);
#foreach my $file (@files) {
#	if ( $file eq "." || $file eq ".." ) {next } { # ignore dir struct
#		if (unlink ($destIP_Dir.$file) != 0) { } else {print "Warning: $destIP_Dir.$file NOT Cleaned!\n"; }}
#}
unlink( $destIP_Dir.$output_filename );


#
# Transport Info
#

my $line = 1;
my $sheet = 1; # sheet one is the Globals tab

# Loop through the sheet to collect alias Transport info
while( $ref->[$sheet]{'A'.$line} ne undef || $line < 10 ) {
	
	my $fileName = $destIP_Dir.$output_filename;
	my $flowName = $ref->[$sheet]{'A'.$line};
	my $srcIP = $ref->[$sheet]{'E'.$line};
	my $dstIP = $ref->[$sheet]{'G'.$line};
	my $dstPort = $ref->[$sheet]{'H'.$line};
	
	
	# Remove some of the lines that we dont want to show
	# up in our alias based on a field for example a header field
	if( $flowName ne "" &&
		$flowName ne "_" && 
		$srcIP ne "Source IP" && 
		$flowName ne "Source Name" &&
		$flowName ne "Source Name_Ad Zone" && 
		$dstIP ne "" &&
		$flowName ne "Global" ){
			
		# Flowname with sheet prefix
		$flowName = 'Global-'.$flowName;
	
		# Puts this line up into the $probes array.  Everyone with the same
		# name will be treated as belonging to the same alias file output
		$probes{$probe} = $probe;
	
		# Create the flow object.  One object per transport flow
		my $tmp_flow = eval { new ipFlow(); } or die ($@);
		
		# These are the fileds populating that flow object.  This is the
		# transport line in the alias file
		$tmp_flow->fileName( $fileName );
	    $tmp_flow->flowName( $flowName );
	    if( $srcIP eq "TBD" ) { $tmp_flow->srcIP( "No" ); } else { $tmp_flow->srcIP( $srcIP ); }
		$tmp_flow->dstIP( $dstIP );
		$tmp_flow->dstPort( $dstPort );
		$tmp_flow->broadcast( $broadcast );
		$tmp_flow->igmpSets( $igmpSets );
		$tmp_flow->ports( $ports );
		$tmp_flow->alarmTemplate( $transportAlarmTemplate );
		
		# Putting this object into a big array for storage so it can be
		# outputed later
		$allFlows{$flowName} = $tmp_flow;
		
	}
	
	$line++;
}

$line = 1;
$sheet = 2; # Sheet 3 is the HOTG SC tab

# Loop through the sheet to collect alias Transport info
while( $ref->[$sheet]{'A'.$line} ne undef || $line < 10 ) {

	my $fileName = $destIP_Dir.$output_filename;
	my $flowName = $ref->[$sheet]{'A'.$line};
	my $srcIP = $ref->[$sheet]{'E'.$line};
	my $dstIP = $ref->[$sheet]{'G'.$line};
	my $dstPort = $ref->[$sheet]{'H'.$line};
	
	# Remove some of the lines that we dont want to show
	# up in our alias based on a field for example a header field
	if( $flowName ne "" &&
		$flowName ne "_" && 
		$srcIP ne "Source IP" && 
		$flowName ne "Source Name" &&
		$flowName ne "Source Name_Ad Zone" && 
		$dstIP ne "" &&
		$flowName ne "Global" ){
			
		# Flowname with sheet prefix
		$flowName = 'HOTG-SC-'.$flowName;

		# Puts this line up into the $probes array.  Everyone with the same
		# name will be treated as belonging to the same alias file output
		$probes{$probe} = $probe;
	
		# Create the flow object.  One object per transport flow
		my $tmp_flow = eval { new ipFlow(); } or die ($@);
		
		# These are the fileds populating that flow object.  This is the
		# transport line in the alias file
		$tmp_flow->fileName( $fileName );
	    $tmp_flow->flowName( $flowName );
		if( $srcIP eq "TBD" ) { $tmp_flow->srcIP( "No" ); } else { $tmp_flow->srcIP( $srcIP ); }
		$tmp_flow->dstIP( $dstIP );
		$tmp_flow->dstPort( $dstPort );
		$tmp_flow->broadcast( $broadcast );
		$tmp_flow->igmpSets( $igmpSets );
		$tmp_flow->ports( $ports );
		$tmp_flow->alarmTemplate( $transportAlarmTemplate );
		
		# Putting this object into a big array for storage so it can be
		# outputed later
		$allFlows{$flowName} = $tmp_flow;
		
	}
	
	$line++;
}

$line = 1;
$sheet = 4; # Charlotte Tab

# Loop through the sheet to collect alias Transport info
while( $ref->[$sheet]{'A'.$line} ne undef || $line < 10 ) {

	my $fileName = $destIP_Dir.$output_filename;
	my $flowName = $ref->[$sheet]{'A'.$line}.'_'.$ref->[$sheet]{'B'.$line};
	my $srcIP = $ref->[$sheet]{'G'.$line};
	my $dstIP = $ref->[$sheet]{'H'.$line};
	my $dstPort = $ref->[$sheet]{'I'.$line};
	
	# Remove some of the lines that we dont want to show
	# up in our alias based on a field for example a header field
	if( $flowName ne "" &&
		$flowName ne "_" && 
		$srcIP ne "Source IP" && 
		$flowName ne "Source Name" &&
		$flowName ne "Source Name_Ad Zone" && 
		$dstIP ne "" &&
		$flowName ne "Global" ){
			
		# Flowname with sheet prefix
		$flowName = 'CHT-'.$flowName;

		# Puts this line up into the $probes array.  Everyone with the same
		# name will be treated as belonging to the same alias file output
		$probes{$probe} = $probe;
	
		# Create the flow object.  One object per transport flow
		my $tmp_flow = eval { new ipFlow(); } or die ($@);
		
		# These are the fileds populating that flow object.  This is the
		# transport line in the alias file
		$tmp_flow->fileName( $fileName );
	    $tmp_flow->flowName( $flowName );
		if( $srcIP eq "TBD" ) { $tmp_flow->srcIP( "No" ); } else { $tmp_flow->srcIP( $srcIP ); }
		$tmp_flow->dstIP( $dstIP );
		$tmp_flow->dstPort( $dstPort );
		$tmp_flow->broadcast( $broadcast );
		$tmp_flow->igmpSets( $igmpSets );
		$tmp_flow->ports( $ports );
		$tmp_flow->alarmTemplate( $transportAlarmTemplate );
		
		# Putting this object into a big array for storage so it can be
		# outputed later
		$allFlows{$flowName} = $tmp_flow;
		
	}
	
	$line++;
}

#
# Program Info
#

$line = 1;
$sheet = 1;

# Loop through the sheet to collect alias Program info
while( $ref->[$sheet]{'A'.$line} ne undef || $line < 10 ) {
	
	my $fileName = $destIP_Dir.$output_filename;
	my $primaryFlowName = $ref->[$sheet]{'A'.$line};
	my $mpegSPTSNumber = '1';
	my $programName = $ref->[$sheet]{'A'.$line};
	my $dstIP = $ref->[$sheet]{'G'.$line};
	
	if( $primaryFlowName ne "" &&
		$primaryFlowName ne "_" && 
		$primaryFlowName ne "Global" &&
		$primaryFlowName ne "Source Name_Ad Zone" &&
		$dstIP ne "" &&
		$primaryFlowName ne "Source Name" ){
			
		# Flowname with sheet prefix
		$primaryFlowName = 'Global-'.$primaryFlowName;
		
		my $tmp_program = eval { new program(); } or die ($@);
		
		$tmp_program->fileName($fileName);
		$tmp_program->flowName($primaryFlowName);
		$tmp_program->channelNumber($mpegSPTSNumber);
		$tmp_program->channelName($programName);
		$tmp_program->payloadTemplate($programAlarmTemplate);
		
		push( @allPrograms, $tmp_program );
	}
	
	$line++;
}

$line = 1;
$sheet = 2;

# Loop through the sheet to collect alias Program info
while( $ref->[$sheet]{'A'.$line} ne undef || $line < 10 ) {
	
	my $fileName = $destIP_Dir.$output_filename;
	my $primaryFlowName = $ref->[$sheet]{'A'.$line};
	my $mpegSPTSNumber = '1';
	my $programName = $ref->[$sheet]{'A'.$line};
	my $dstIP = $ref->[$sheet]{'G'.$line};
	
	if( $primaryFlowName ne "" &&
		$primaryFlowName ne "_" && 
		$primaryFlowName ne "Global" &&
		$primaryFlowName ne "Source Name_Ad Zone" &&
		$dstIP ne "" &&
		$primaryFlowName ne "Source Name" ){
			
		# Flowname with sheet prefix
		$primaryFlowName = 'HOTG-SC-'.$primaryFlowName;
		
		my $tmp_program = eval { new program(); } or die ($@);
		
		$tmp_program->fileName($fileName);
		$tmp_program->flowName($primaryFlowName);
		$tmp_program->channelNumber($mpegSPTSNumber);
		$tmp_program->channelName($programName);
		$tmp_program->payloadTemplate($programAlarmTemplate);
		
		push( @allPrograms, $tmp_program );
	}
	
	$line++;
}

$line = 1;
$sheet = 4;

# Loop through the sheet to collect alias Program info
while( $ref->[$sheet]{'A'.$line} ne undef || $line < 10 ) {
	
	my $fileName = $destIP_Dir.$output_filename;
	my $primaryFlowName = my $flowName = $ref->[$sheet]{'A'.$line}.'_'.$ref->[$sheet]{'B'.$line};
	my $mpegSPTSNumber = '1';
	my $programName = $ref->[$sheet]{'A'.$line};
	my $dstIP = $ref->[$sheet]{'G'.$line};
	
	if( $primaryFlowName ne "" &&
		$primaryFlowName ne "_" && 
		$primaryFlowName ne "Global" &&
		$primaryFlowName ne "Source Name_Ad Zone" &&
		$dstIP ne "" &&
		$primaryFlowName ne "Source Name" ){
			
		# Flowname with sheet prefix
		$primaryFlowName = 'CHT-'.$primaryFlowName;
		
		my $tmp_program = eval { new program(); } or die ($@);
		
		$tmp_program->fileName($fileName);
		$tmp_program->flowName($primaryFlowName);
		$tmp_program->channelNumber($mpegSPTSNumber);
		$tmp_program->channelName($programName);
		$tmp_program->payloadTemplate($programAlarmTemplate);
		
		push( @allPrograms, $tmp_program );
	}
	
	$line++;
}

#################################
#################################


#print Dumper(%allFlows);
#>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>  Create Alias Files >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
foreach my $probe (keys %probes) {
	print "Probe $probe\n";
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
	foreach my $flow (values %allFlows){
		$numFlows++;
		#print ".";
		$flow->printFlows();
	}
	print "$numFlows\n";
	%allFlows = (); 
	$numFlows = 0;

#print Dumper(@allPrograms);
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
