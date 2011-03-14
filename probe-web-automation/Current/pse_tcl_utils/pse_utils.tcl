package require iqtclapid
source iq_utils.tcl

proc pse_issue_marker_to_xPRT { marker_text } {

	# Not sure how to do this.  Waiting for Lynn's reply on what to do here.
	
}

proc pse_ConnectTo { target } {

	#####################################
	# Open Connection
	#####################################
	# Connect to the targets - catch the exception
	
	iqPrint "Connecting to "
	iqPrint $target
	iqPrint "..."
	
	if {[catch { set handle [iqtcl_ConnectTo $target] } result] } {
		set status "Open Connection Failure to "
		append status $target ": " $result
		ErrorAndClose $status
	}
	
	iqPrint "done\n"
	
	return $handle
}
proc pse_OpenStimulus { up_handle up_stimHandle } {

	upvar 1 $up_handle handle
	upvar 1 $up_stimHandle stimHandle
	
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
}
proc pse_DownloadStimulusFile { up_handle up_stimHandle filePath srcMac destMac vlanID tosField srcIP dstIP srcPort dstPort rtpType encType } {

	upvar 1 $up_handle handle
	upvar 1 $up_stimHandle stimHandle
	
	#####################################
	# Download the file to target
	#####################################
	set dataFile "/opt/ineoquest/gkan/a.ts"
	
	iqPrint "Downloading file "
	iqPrint $dataFile
	iqPrint "..."
	
	#set srcMac [binary format H* 000AAAAAAAAA]
	#set destMac [binary format H* 000BBBBBBBBB]
	
	# iqtcl_DownloadStimulusFile  iqtcl_LoadDefaultFile
	# iqtcl_DownloadStimulusFile - dont seem to work.  It always hangs with no error message
	
	if {[catch { iqtcl_LoadDefaultFile $handle $stimHandle $srcMac $destMac $vlanID $tosField $srcIP $dstIP $srcPort $dstPort $rtpType $encType } result] } {
		set status "Download stimulus failure: "
		append status $result
		ErrorAndClose $status
	}
	
	iqPrint "done\n"
}

proc pse_SetXCount { up_handle up_stimHandle numCopies } {

	upvar 1 $up_handle handle
	upvar 1 $up_stimHandle stimHandle
	
	#####################################
	# Update the stream count
	#####################################
	
	#set numCopies 20
	
	iqPrint "Setting num copies to "
	iqPrint $numCopies
	iqPrint "..."
	
	if {[catch { iqtcl_SetXCount $handle $stimHandle $numCopies } result] } {
		set status "Set XCount failure: "
		append status $result;
		ErrorAndClose $status
	}
	
	iqPrint "done\n"
}

proc pse_StartStimulus { up_handle up_stimHandle } {

	upvar 1 $up_handle handle
	upvar 1 $up_stimHandle stimHandle

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

}
proc pse_StopStimulus { up_handle up_stimHandle } {

	upvar 1 $up_handle handle
	upvar 1 $up_stimHandle stimHandle
	
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

}

proc pse_CloseStimulus { up_handle up_stimHandle } {

	upvar 1 $up_handle handle
	upvar 1 $up_stimHandle stimHandle
	
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

}
proc pse_CloseConnection { up_handle up_stimHandle } {

	upvar 1 $up_handle handle
	upvar 1 $up_stimHandle stimHandle
	
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

}

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
proc pse_SetIPDrops { up_handle up_stimHandle mode drops pass } {
# To drop 10 every 100 packets:
# set mode	4, set drops 10, set pass 90

	upvar 1 $up_handle handle
	upvar 1 $up_stimHandle stimHandle
	
	#####################################
	# Set IP Drops
	#####################################
	
	iqPrint "Setting drops: "
	#iqPrint $mode
	iqPrint "..."
	
	if {[catch { iqtcl_SetIPDrops $handle $stimHandle $mode $drops $pass } result] } {
		set status "Set XCount failure: "
		append status $result;
		ErrorAndClose $status
	}
	
	iqPrint "done\n"
}
proc pse_SetIPJitter { up_handle up_stimHandle mode drops pass } {
#
# The documentation for this function looks wrong.  It says to drop but you dont want
# to drop for jitter.  Have to check with the doc team
#
#

# To drop 10 every 100 packets:
# set mode 3 set drops 10 set pass 100

	upvar 1 $up_handle handle
	upvar 1 $up_stimHandle stimHandle
	
	#####################################
	# Set IP Drops
	#####################################
	
	iqPrint "Setting drops: "
	#iqPrint $mode
	iqPrint "..."
	
	if {[catch { iqtcl_SetIPJitter $handle $stimHandle $mode $drops $pass } result] } {
		set status "Set XCount failure: "
		append status $result;
		ErrorAndClose $status
	}
	
	iqPrint "done\n"
}
proc pse_SetDFJitter { up_handle up_stimHandle jitter } {

	upvar 1 $up_handle handle
	upvar 1 $up_stimHandle stimHandle
	
	#####################################
	# Set Jitter
	#####################################
	
	iqPrint "Setting Jitter: "
	#iqPrint $jitter
	iqPrint "..."
	
	if {[catch { iqtcl_SetDFJitter $handle $stimHandle $jitter } result] } {
		set status "Set XCount failure: "
		append status $result;
		ErrorAndClose $status
	}
	
	iqPrint "done\n"
}
proc pse_StopIPJitter { up_handle up_stimHandle } {

	upvar 1 $up_handle handle
	upvar 1 $up_stimHandle stimHandle
	
	#####################################
	# Set Jitter
	#####################################
	
	iqPrint "Stopping Jitter: "
	iqPrint "..."
	
	if {[catch { iqtcl_StopIPJitter $handle $stimHandle } result] } {
		set status "Set XCount failure: "
		append status $result;
		ErrorAndClose $status
	}
	
	iqPrint "done\n"
}
proc pse_StopDFJitter { up_handle up_stimHandle } {

	upvar 1 $up_handle handle
	upvar 1 $up_stimHandle stimHandle
	
	#####################################
	# Set StopDFJitter
	#####################################
	
	iqPrint "Stopping StopDFJitter: "
	iqPrint "..."
	
	if {[catch { iqtcl_StopDFJitter $handle $stimHandle } result] } {
		set status "Set XCount failure: "
		append status $result;
		ErrorAndClose $status
	}
	
	iqPrint "done\n"
}
proc pse_SetBitrate { up_handle up_stimHandle type newBitrate } {
# type The detection mode for the bitrare - can be one of the following values
# 		0 = Default mode, 1 = Detected Bitrate, 2 = Received Bitrate, 3 = User Defined Bitrate
# newBitrate = 3500000 = 3.5Mb/s

	upvar 1 $up_handle handle
	upvar 1 $up_stimHandle stimHandle
	
	#####################################
	# Set SetBitrate
	#####################################
	
	iqPrint "Setting SetBitrate: "
	#iqPrint $newBitrate
	iqPrint "..."
	
	if {[catch { iqtcl_SetBitrate $handle $stimHandle $type $newBitrate } result] } {
		set status "Set XCount failure: "
		append status $result;
		ErrorAndClose $status
	}
	
	iqPrint "done\n"
}