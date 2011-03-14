#!/bin/sh

source pse_utils.tcl

proc testing_the_functions { circuit_name ip_test_port udp_port_start qos_bits total_bandwidth num_of_flows } {

	# API Vars
	set handle		-1
	set stimHandle	-1
	set isRunning	0
	
	# Stim Settings
	set filePath "/opt/ineoquest/gkan/a.ts"
	set srcMac [binary format H* 000AAAAAAAAA]
	set destMac [binary format H* 000BBBBBBBBB]
	set vlanID 0
	set tosField $qos_bits
	set srcIP "1.1.1.1"
	set dstIP "2.2.2.2"
	set srcPort "1111"
	set dstPort "2222"
	set rtpType 0
	set encType 0
	
	# Update count
	set numCopies 19
	
	set handle [ pse_ConnectTo $ip_test_port ]
	
	pse_OpenStimulus handle stimHandle

	pse_DownloadStimulusFile handle stimHandle $filePath $srcMac $destMac $vlanID $tosField $srcIP $dstIP $srcPort $dstPort $rtpType $encType

	pse_SetXCount handle stimHandle $numCopies
	
	pse_SetDFJitter handle stimHandle 100
	
	# pse_SetBitrate handle stimHandle 1 3500000

	pse_StartStimulus handle stimHandle
	
	# pse_StopIPJitter handle stimHandle
	
	pse_StopDFJitter handle stimHandle
	
	pse_StopStimulus handle stimHandle
	
	pse_CloseStimulus handle stimHandle
	
	pse_CloseConnection handle stimHandle
	
	pse_issue_marker_to_xPRT "something to the marker"
	
}

proc single_circuit_test { circuit_name ip_test_port udp_port_start qos_bits total_bandwidth num_of_flows } {
#####################################
# Will connect to 2 different stim, load the strim files, and start a test
#####################################

	# API Vars for Stim 1
	set handle_1		-1
	set stimHandle_1	-1
	set isRunning_1		0
	
	# API Vars for Stim 2
	set handle_2		-1
	set stimHandle_2	-1
	set isRunning_2		0
	
	# Stim Settings for Stim 1
	set stim1_ip "172.17.2.109"
	set filePath_1 "/opt/ineoquest/gkan/a.ts"
	set srcMac_1 [binary format H* 000AAAAAAAAA]
	set destMac_1 [binary format H* 000BBBBBBBBB]
	set vlanID_1 0
	set tosField_1 $qos_bits
	set srcIP_1 "1.1.1.1"
	set dstIP_1 "2.2.2.2"
	set srcPort_1 "1111"
	set dstPort_1 "2222"
	set rtpType_1 0
	set encType_1 0
	
	# Stim Settings for Stim 2
	set stim2_ip "172.17.2.110"
	set filePath_2 "/opt/ineoquest/gkan/a.ts"
	set srcMac_2 [binary format H* 000AAAAAAAAA]
	set destMac_2 [binary format H* 000BBBBBBBBB]
	set vlanID_2 0
	set tosField_2 $qos_bits
	set srcIP_2 "1.1.1.1"
	set dstIP_2 "2.2.2.2"
	set srcPort_2 "1111"
	set dstPort_2 "2222"
	set rtpType_2 0
	set encType_2 0
	
	# Update count
	set numCopies_1 19
	set numCopies_2 19
	
	set handle_1 [ pse_ConnectTo $stim1_ip ]
	set handle_2 [ pse_ConnectTo $stim2_ip ]
	
	pse_OpenStimulus handle_1 stimHandle_1
	pse_OpenStimulus handle_2 stimHandle_1

	pse_DownloadStimulusFile handle_1 stimHandle_1 $filePath_1 $srcMac_1 $destMac_1 $vlanID_1 $tosField_1 $srcIP_1 $dstIP_1 $srcPort_1 $dstPort_1 $rtpType_1 $encType_1
	pse_DownloadStimulusFile handle_2 stimHandle_2 $filePath_2 $srcMac_2 $destMac_2 $vlanID_2 $tosField_2 $srcIP_2 $dstIP_2 $srcPort_2 $dstPort_2 $rtpType_2 $encType_2

	pse_SetXCount handle_1 stimHandle_1 $numCopies_1
	pse_SetXCount handle_2 stimHandle_2 $numCopies_2

	pse_StartStimulus handle_1 stimHandle_1
	pse_StartStimulus handle_2 stimHandle_2
	
	pse_StopStimulus handle_1 stimHandle_1
	pse_StopStimulus handle_2 stimHandle_2
	
	pse_CloseStimulus handle_1 stimHandle_1
	pse_CloseStimulus handle_2 stimHandle_2
	
	pse_CloseConnection handle_1 stimHandle_1
	pse_CloseConnection handle_2 stimHandle_2
	
}

#testing_the_functions "circuit name" "172.17.2.109" "udp_port_start"  "qos_bits"  "total_bandwidth"  "num_of_flows"
testing_the_functions "circuit name" "172.17.2.109" "0"  "0"  "total_bandwidth"  "num_of_flows"

