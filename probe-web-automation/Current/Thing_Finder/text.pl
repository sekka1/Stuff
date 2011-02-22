#!/usr/bin/perl

use strict;
use TEXT;

if(@ARGV > 1){

	my $text = TEXT->new();
	
	$text->getDefinitionFile( "definition_files/search1.txt" );
	
	$text->getPathAndSubDirsFiles();
	
	$text->searchFile();
	
	my $results = $text->getSearchResults();
	
	foreach my $result (@{$results}){
		print $result . "\n";
	}
	
}
