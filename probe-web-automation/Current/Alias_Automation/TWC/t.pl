#!/usr/bin/perl
use strict;

my $st = "A&A";

$st = stringtrimmer($st);

print $st;

sub stringtrimmer($)
        {
        my $string = shift;
        my $oldstring = $string;        
        $string =~ s/^\s+//; #remove leading WHTSPC
        $string =~ s/\s+$//; #remove trailing WHTSPC
       # $string =~ s/\s/_/ig; #convert spaces to _
        $string =~ s/\!/-/ig; #convert ! to - (E! television)
        $string =~ s/\'/_/ig; #convert ' to _ (Women's Ent.)
        $string =~ s/\`/_/ig;
        $string =~ s/\//-/ig; #convert / to - 
        $string =~ s/\\/-/ig; #convert \ to -
        $string =~ s/\+/_/ig; #convert + to _  
        $string =~ s/\&/-/ig; #convert & to - (A&E )
        $string =~ s/\&/-/ig; #convert & to - (A&E )        
        $string =~ s/\&amp/-/ig; #handle html encoded &
        $string =~ s/[^a-zA-Z0-9_\-\.\s]+//g; #allow only a-z A-Z 0-9 _ - .
        
        if ($oldstring ne $string)
        {
        	print "Replacing - " . $string . " - " . $oldstring . "\n";
        }
        
        return $string;
        }   
