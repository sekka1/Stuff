#!/usr/bin/perl
# vim: set expandtab tabstop=4 shiftwidth=4 softtabstop=4 foldmethod=marker: #

#
# This module is used to search in text file for the specified string(s)
#

package TEXT;
use strict;

sub new {
	
	my $self  = {};

	$self->{definition_file_path} = undef;
	
	# Definition Items
	$self->{search_type} = '';
	$self->{search_location} = [];
	$self->{search_term} = [];
	$self->{line_returned} = '';
	
	# Array holding full paths to Files for Search
	$self->{files_search_array} = []; # Declare an Array
	
	# Array holding the search results
	$self->{files_search_results} = []; # Declare an Array
    
    bless($self);
    
    return $self;
}
sub getDefinitionFile{
	
	my $self = shift;

    $self->{definition_file_path} = $_[0];
    
    open( FILE, $self->{definition_file_path} ) || die("Could not open file!"); 
    
    while( my $line = <FILE> ){
    	my $item = $self->getDefinitionItem( $line );
    }
    
    close( FILE );
    
}
sub getDefinitionItem{
# Parses the name=value pairs from the definition file and puts them into
# the correct variable for this class to use

	my $self = shift;
	
	my $line = $_[0];
	
	$line =~ s/\n//g;
	
	my @temp = split( /=/, $line );
	
	if( $temp[0] eq 'search_type' ){ $self->{search_type} = $temp[1]; }
	elsif( $temp[0] eq 'search_location' ){ 
		# There might be one or more of these		
		push( @{$self->{search_location}}, $temp[1] );
	}
	elsif( $temp[0] eq 'search_term' ){ 
		# There might be one or more of these		
		push( @{$self->{search_term}}, $temp[1] );	
	}
	elsif( $temp[0] eq 'line_returned' ){ $self->{line_returned} = $temp[1]; }
	
}
sub getPathAndSubDirsFiles{
# Get all the dirs and sub dirs to all the paths the user has specified

	my $self  = shift;

	#my @paths = split( /\|\|\|/, $self->{search_location} );
	
	my @all_search_paths = undef;

	foreach my $item ( @{$self->{search_location}} ){
#		print "a path: " . $item . "\n";
		if( -f $item ){
			push( @{$self->{files_search_array}}, $item );
#			print $item . " - found file\n";
		}
		if( -d $item ){
#			print "found directory\n";
			$self->lookInDirForFiles( $item );
		}
	}
	
#	foreach my $a_file ( @{$self->{files_search_array}} ){
#		print $a_file . "\n";	
#	}
}
sub lookInDirForFiles{
# Recursive search for files in a given directory

	my $self  = shift;
	
	my $dir = $_[0];

	#Get everything in this directory
	opendir( my($dh), $dir ) || die "can't opendir $dir\n";
	
	# Take out the dirs with . and ..
	my @files = grep { !/^\.\.?$/ } readdir $dh;
	
	foreach my $file ( @files ){
#		print "B path: " . $dir.$file . "\n";
		if( -f $dir.$file ){
			push( @{$self->{files_search_array}}, $dir.$file );
#			print $file . " - found file\n";
		}
		if( -d $dir.$file ){
			
#					print $file . " - found directory\n";
					$self->lookInDirForFiles( $dir.$file.'/' );
		}
	}
	closedir( $dh );

}
sub searchFile{
# This function takes the list of the files found in the directory paths that
# the user has specified in the config file and foreach file it opens and looks
# for the search term(s) that the user specified in the config file on each line.
# When there is a match it will put it into the $self->{files_search_results} array.
#
# It does this in 2 loops after opening the file. It first opens the file then
# it loops through every single line in the text file and eval it to each of the
# search terms.  When it is found it puts that line number into an array.
# Then it takes the array with the line number and take the pre and post number of
# lines that the user wants and puts it into the files_search_results array

	my $self  = shift;
	
	# Go through the file list and open each file to be searched
	foreach my $a_file ( @{$self->{files_search_array}} ){
#		print $a_file . " - a_file\n";
		
		# Used to retrieve the previous lines if the users want
		# lines surrounding the search target.  Saving the entire
		# file so that it can later get pre and post lines from the
		# point of the search target
		my @save_file_history = [];
		
		# Array holding which line of the file the search target was found
		my @search_target_hit = [];
		
		# Counter for the lines
		my $line_counter = 0;
		
		# Open File
		open( FILE, $a_file ) || die("Could not open file!"); 
    
    	# Search through each line of the file
    	while( my $line = <FILE> ){
    		
    		# Saving each line to be used later
    		push( @save_file_history, $line );
    		
    		foreach my $a_search_term ( @{$self->{search_term}} ){
    			if( $line =~ /$a_search_term/ ){
    				# Put this hit and the line it was at into the array
    				push( @search_target_hit, $line_counter);
#print $line_counter . " - hit\n";
    			}
    		}
    		
    		$line_counter++;
    		
    	}
#print "finished searching\n";

    	# Put the found targets into the files_saerch_results array
    	# With the user's specified surrounding lines included
    	if( @search_target_hit > 0 ){
    		
    		foreach my $search_hit_line_number ( @search_target_hit ){
    			
    			if( $save_file_history[$search_hit_line_number+1] ne '' ){
	    			my $temp_result_save = '';
	    			
	    			# If user wants to save surrounding lines
	    			if( $self->{line_returned} > 0 ){
	
#	print "start saving\n";
#	print "saving - " . $save_file_history[$search_hit_line_number+1] . "\n";

						# Put file name into the result
						$temp_result_save .= "File: " . $a_file . "\n";
	
	    				# Get the pre search target lines
	    				for( my $i=$search_hit_line_number-$self->{line_returned}+1; $i<=$search_hit_line_number; $i++){
	    				
	    					if( $i > 0 ){
	    						$temp_result_save .= "line $i - " . $save_file_history[$i];
	    					}
	    				}
	    				
	    				# Put the search target into temp_result_save
	    				$temp_result_save .= "++++++++++++++++++++++++++++\n";
	    				$temp_result_save .= $save_file_history[$search_hit_line_number+1];
	    				$temp_result_save .= "++++++++++++++++++++++++++++\n";
	    				
	    				# Get the post search target lines.
	    				for( my $n=$search_hit_line_number+2; $n<$search_hit_line_number+$self->{line_returned}+2; $n++ ){
	    		
	    					if( $n < @save_file_history ){
	    						$temp_result_save .= "line $n - " . $save_file_history[$n];
	    					}
	    				}
	    				
	    				# Put results into the files_search_results
	    				push( @{$self->{files_search_results}}, $temp_result_save );
	    				
	    			} else {
	    				# User dont want any lines surrounding the search target 
	    				push( @{$self->{files_search_results}}, $save_file_history[$search_hit_line_number] );
	    			}
    			
    			}	
    		}
    	}
    
    	close( FILE );
	}
	
	# Printing out everything in the files_search_results array
#	print "====================================\n";
#	foreach my $line (@{$self->{files_search_results}}){
#		print "begin result:\n";
#		print $line;
#		print "end of result\n\n\n"
#	}

}
sub getSearchResults{
	
	my $self  = shift;
	
	return $self->{files_search_results};
}

1;