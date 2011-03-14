#!/bin/sh
package require iqtclapid

#####################################
# Source any helper scripts
#####################################
source iq_utils.tcl

#####################################
# Local Helper Methods
#####################################
proc ErrorAndClose { status } {

	global handle

	# print error
	iqPrint "Error: "
	iqPrint $status
	iqPrint "\n"

	if {$handle != -1} {
		iqtcl_CloseConnection $handle
	}

	# get user ack
	iqPrint "Hit <ENTER> to exit"
	set answer [gets stdin]
	exit
}

#####################################
# Initialization
#####################################
set handle		-1


#####################################
# Open Connection
#####################################
# Connect to the target - catch the exception
set target "172.17.2.109"

iqPrint "Connecting to "
iqPrint $target
iqPrint "..."

if {[catch { set handle [iqtcl_ConnectTo $target] } result] } {
	set status "Open Connection Failure to "
	append status $target ": " $result
	ErrorAndClose $status
}

iqPrint "done\n"


#####################################
# Test iqtcl_CloseOldConnections
#
#####################################
iqPrint "testing iqtcl_CloseOldConnections..."

if {[ catch { iqtcl_CloseOldConnections $handle } result] } {
	set status "Error: "
#	append status $result
	iqPrint $status
}

iqPrint "done.\n"


#####################################
# Test iqtcl_IsConnected
#####################################
iqPrint "iqtcl_IsConnected returns "

if {[ catch { set state [iqtcl_IsConnected $handle] } result] } {
	set status "Error: "
	append status $result
	iqPrint $status
}

iqPrint $state
iqPrint "\n"



#####################################
# Test iqtcl_SaveSessionData
#
#####################################

#####################################
# Test iqtcl_CloseSession
#
#####################################
iqPrint "testing iqtcl_CloseSession..."

if {[ catch { iqtcl_CloseSession $handle } result] } {
	set status "Error: "
	append status $result
	iqPrint $status
}

iqPrint "done.\n"


#####################################
# Test iqtcl_RetrieveSessionData
#
#####################################

#####################################
# Test iqtcl_ResumeSession
#
#####################################



#####################################
# Close Connection
#####################################
iqPrint "Closing Connection..."

if {[catch { iqtcl_CloseConnection $handle } result] } {
	set status "Close Connection failure: "
	append status $result
	ErrorAndClose $status 
}

iqPrint "done\n"


#####################################
# Test iqtcl_IsConnected
#####################################
iqPrint "iqtcl_IsConnected returns "

if {[ catch { set state [iqtcl_IsConnected $handle] } result] } {
	set status "Error: "
	append status $result
	iqPrint $status
}

iqPrint $state
iqPrint "\n"
