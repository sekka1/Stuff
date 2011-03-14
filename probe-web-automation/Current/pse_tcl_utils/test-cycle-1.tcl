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
	global stimHandle
	global isRunning

	# print error
	iqPrint "Error: "
	iqPrint $status
	iqPrint "\n"

	if {$isRunning == 1} {
		iqtcl_StopStimulus $handle $stimHandle
	}

	if {$stimHandle != -1} {
		iqtcl_CloseStimulus $handle $stimHandle
	}

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
set stimHandle	-1
set isRunning	0

#####################################
# Open Connection
#####################################
# Connect to the targets - catch the exception
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
# Open a Stimulus Session
#####################################
iqPrint "Opening Stimulus Session..."

# Open Stimulus Session
if {[catch { set stimHandle [iqtcl_OpenStimulus $handle] } result] } {
	set status "Open Stimulus Failure: "
	append status $result
	ErrorAndClose $status 
}

iqPrint "done.\n"

#####################################
# Download the file to target
#####################################
set dataFile "/opt/ineoquest/gkan/a.ts"

iqPrint "Downloading file "
iqPrint $dataFile
iqPrint "..."

set srcMac [binary format H* 000AAAAAAAAA]
set destMac [binary format H* 000BBBBBBBBB]

#if {[catch { iqtcl_DownloadStimulusFile $handle $stimHandle $dataFile $srcMac $destMac 0 0 192.168.10.1 192.168.10.3 400 600 0 0 } result] } {
if {[catch { iqtcl_LoadDefaultFile $handle $stimHandle $srcMac $destMac 0 0 192.168.10.1 192.168.10.3 400 600 0 0 } result] } {
	set status "Download stimulus failure: "
	append status $result
	ErrorAndClose $status
}

iqPrint "done\n"

#####################################
# Update the stream count
#####################################

set numCopies 20

iqPrint "Setting num copies to "
iqPrint $numCopies
iqPrint "..."

if {[catch { iqtcl_SetXCount $handle $stimHandle $numCopies } result] } {
	set status "Set XCount failure: "
	append status $result;
	ErrorAndClose $status
}

iqPrint "done\n"

#####################################
# Start Stimulus Session
#####################################
iqPrint "Starting Stimulus..."

# mod destIP
set modMask 64
set modValue 1
set	outPort 0
set numRecords 7
set numLoops 0

if {[catch { iqtcl_StartStimulus $handle $stimHandle $modMask $modValue $outPort $numRecords $numLoops } result] } {
	set status "Start stimulus failure: "
	append status $result
	ErrorAndClose $status
}

iqPrint "done.\n"
set isRunning 1

# Sleep for 10 seconds
iqPrint "\nSleeping 10 seconds...\n"
after 10000

#####################################
# Update the stream count
#####################################
set numCopies 50

iqPrint "Updating num copies to "
iqPrint $numCopies
iqPrint "..."

if {[catch { iqtcl_SetXCount $handle $stimHandle $numCopies } result] } {
	set status "Set XCount failure: "
	append status $result;
	ErrorAndClose $status
}

iqPrint "done\n"

# Sleep for 10 seconds
iqPrint "\nSleeping 10 seconds...\n"
after 10000

#####################################
# Update the stream count
#####################################
set numCopies 0

iqPrint "Updating num copies to "
iqPrint $numCopies
iqPrint "..."

if {[catch { iqtcl_SetXCount $handle $stimHandle $numCopies } result] } {
	set status "Set XCount failure: "
	append status $result;
	ErrorAndClose $status
}

iqPrint "done\n"

# Sleep for 10 seconds
iqPrint "\nSleeping 10 seconds...\n"
after 10000

#####################################
# Stop Stimulus Session
#####################################
iqPrint "Stopping Stimulus..."

if {[catch { iqtcl_StopStimulus $handle $stimHandle } result] } {
	set status "Stop stimulus failure: "
	append status $result
	ErrorAndClose $status
}

iqPrint "done.\n"
set isRunning 0

#####################################
# Close Stimulus Session
#####################################
iqPrint "Closing Stimulus Session..."

if {[catch { iqtcl_CloseStimulus $handle $stimHandle } result] } {
	set status "Close Stimulus Failure: "
	append status $result
	ErrorAndClose $status
}

iqPrint "done.\n"

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



