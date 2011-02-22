#!/usr/bin/perl

# This show an example of usage of the Alias classes to parse out one tab in an
# Excel file and create an Alias out of it.

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
my $igmpSets = "1";
my $ports = "3";
my $broadcast = "4";
my $transportAlarmTemplate = 'Standard Transport at IP';
my $programAlarmTemplate = 'Standard Video Service at IP';

#Dump out all the sheets that it read in
#print Dumper($ref->[0]{sheet});

# Print out the first sheet cell A8
#print "xxxx: " . $ref->[1]{'A8'} . "\n\n";

# Delete old alias files from the output directory before going on
opendir(DIR, "$destIP_Dir"); #read IP Dir
my @files = readdir(DIR);
foreach my $file (@files) {
	if ( $file eq "." || $file eq ".." ) {next } { # ignore dir struct
		if (unlink ($destIP_Dir.$file) != 0) { } else {print "Warning: $destIP_Dir.$file NOT Cleaned!\n"; }}
}

my $line = 1;
my $sheet = 1;

# Loop through the sheet to collect alias Transport info
while( $ref->[$sheet]{'A'.$line} ne undef || $line < 10 ) {
	
	# Filename is important.  Every flow with the same file name will be in the
	# same alias file when outputed
	my $fileName = $destIP_Dir.'Global.xls';
	my $flowName = $ref->[$sheet]{'A'.$line};	# Pulling from Column A1 - depending on what $line is
	my $srcIP = $ref->[$sheet]{'E'.$line};
	my $dstIP = $ref->[$sheet]{'G'.$line};
	my $dstPort = $ref->[$sheet]{'H'.$line};
	
	# Remove some of the lines that we dont want to show
	# up in our alias based on a field for example a header field
	if( $flowName ne "" && 
		$srcIP ne "Source IP" && 
		$flowName ne "Source Name" && 
		$flowName ne "Global" ){

		# Puts this line up into the $probes array.  Everything with the same
		# name will be treated as belonging to the same alias file output
		$probes{'Global'} = 'Global';
	
		# Create the flow object.  One object per transport flow
		my $tmp_flow = eval { new ipFlow(); } or die ($@);
		
		# These are the fileds populating that flow object.  This is the
		# transport line in the alias file
		$tmp_flow->fileName( $fileName );
	    $tmp_flow->flowName( $flowName );
		$tmp_flow->srcIP( $srcIP );
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
$sheet = 1;

# Loop through the sheet to collect alias Program info
while( $ref->[$sheet]{'A'.$line} ne undef || $line < 10 ) {
	
	my $fileName = $destIP_Dir.'Global.xls';
	my $primaryFlowName = $ref->[$sheet]{'A'.$line};
	my $mpegSPTSNumber = '1';
	my $programName = $ref->[$sheet]{'A'.$line};
	
	if( $primaryFlowName ne "" && 
		$primaryFlowName ne "Global" && 
		$primaryFlowName ne "Source Name" ){
		
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
