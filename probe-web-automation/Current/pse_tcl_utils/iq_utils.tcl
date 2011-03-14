##########################################################################
# Helper procedures used with the Tcl interface to the
# Ineoquest SingulusG1 Systems
#
# public Procedures Defined:
#		iqPrint
#		ipaddr2hex
#		hex2ipaddr
#		hexnum
#
# private Procedures defined:
##########################################################################

#####################################################################
# Procedure:
#		iqPrint
# Description:
#		prints input to stdout and flushes buffer
#
# Parameters:
#
# Results:
#
####################################################################
proc iqPrint { strData } {
	puts -nonewline $strData
	flush stdout
}

#####################################################################
# Procedure: 
#		ipaddr2hex
# Description: 
#		converts an IP dot-notation address to hex equivalent
#
# Parameters:
#		addr		- the IP address in dot-notation 
#
# Returns:
#		the hex equivalent
#
# NOTES:
#
#######################################################################
proc ipaddr2hex {addr} {

	# split the address
	set ipbytes [split $addr "."]

	# allow for truncated addresses
    if {[llength $ipbytes] != 4} {
        set ipbytes [lrange [concat $ipbytes 0 0 0] 0 3]
    }

	# validate the values
	foreach i $ipbytes {
		if {$i < 0 || $i > 255} {
			return -code error "invalid address"
		}
	}

	binary scan [binary format c4 $ipbytes] H8 x
	return 0x$x
}


#####################################################################
# Procedure: 
#		hex2ipaddr
# Description: 
#		converts an hex IP address to its dot-notation equivalient
#
# Parameters:
#		hexaddr		- the IP address in hex 
#
# Returns:
#		the dot notation equivalent string
#
# NOTES:
#
#######################################################################
proc hex2ipaddr { hexaddr } {

	set ipString {}

	set temp [binary format I [expr {$hexaddr}]]
	binary scan $temp c4 octets

	foreach octet $octets {
		lappend ipString [expr {$octet & 0xFF}]
	}

	return [join $ipString .]
 }

#####################################################################
# Procedure: 
#		hexnum
# Description: 
#		returns a number based on the hex characters passed in
#
# Parameters:
#		hexstring	- the hex characters 
#
# Returns:
#		the hex number
#
# NOTES:
#
#######################################################################
proc hexnum { hexstring } {
	set hexval [format "%d" "0x$hexstring"]
	return $hexval
}

