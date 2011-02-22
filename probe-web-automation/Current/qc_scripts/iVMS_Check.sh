#!/bin/bash
PATH=/usr/bin:/bin:/sbin

INTERACTIVE=0

OS_STATUS=1
NETWORK_STATUS=1
LICENSE_STATUS=1
MYSQL_STATUS=1
DISK_STATUS=1

SETCOLOR_SUCCESS="echo -en \\033[1;32m"
SETCOLOR_FAILURE="echo -en \\033[1;31m"
SETCOLOR_WARNING="echo -en \\033[1;35m"
SETCOLOR_NORMAL="echo -en \\033[0;39m"

ECHO_OK()
{
	string=$1
	$SETCOLOR_SUCCESS
	echo "$string"
	$SETCOLOR_NORMAL
}

ECHO_NOK()
{
	string=$1
	$SETCOLOR_FAILURE
	echo "$string"
	$SETCOLOR_NORMAL
}

ECHO_WARN()
{
	string=$1
	$SETCOLOR_WARNING
	echo "$string"
	$SETCOLOR_NORMAL
}

# Formatted echos
FECHO_OK()
{
	check=$1
	check=`echo $check | sed 's/Check_//'`
	$SETCOLOR_SUCCESS
	echo "	+$check OK"
	$SETCOLOR_NORMAL
}

FECHO_NOK()
{
	check=$1
	check=`echo $check | sed 's/Check_//'`
	$SETCOLOR_FAILURE
	echo "	-$check NOT OK"
	$SETCOLOR_NORMAL
}

FECHO_WARN()
{
	check=$1
	check=`echo $check | sed 's/Check_//'`
	$SETCOLOR_WARNING
	echo "	-$check NOT OK"
	$SETCOLOR_NORMAL
}

#Thresholds
if [ ! `whoami` == "root" ]
then
        echo "This script requires root administrative priileges"
        echo "Please login as root."
        exit 1
fi
if [ "`uname -s`" != "Linux" ]
then
        echo "This script currently only supports Linux"
        exit 1
fi

if [ $# > 0 ]
then
	if [ "$1" == "-i" ]
	then
		INTERACTIVE=1
	fi
fi

Check_OS()
{
	if [ -f /etc/redhat-release ]
	then
	        RELEASE=`cat /etc/redhat-release`
		if [ "$RELEASE" != "Red Hat Enterprise Linux Server release 5 (Tikanga)" ] && [ "$RELEASE" != "Red Hat Enterprise Linux Server release 5.1 (Tikanga)" ] && [ "$RELEASE" != "Red Hat Enterprise Linux Server release 5.2 (Tikanga)" ]
		then
			OS_STATUS=0
			echo "	This system seems to be running an unsupported Red Hat Linux version."
			echo "	Currently running ''$RELEASE''"
		fi
	else
		echo "	The file /etc/redhat-release does not exist"
		echo "	This system seems to be running an unsupported Linux distribution."
	fi
	[ $OS_STATUS == 1 ] && FECHO_OK OS || FECHO_NOK OS
}

Check_Network()
{
	 if [ ! -e /etc/hosts ]
	 then
	 	echo "	You do not have an /etc/hosts file - this is a major system-wide problem for networking."
	 	echo "	Read 'man hosts'"
	 	NETWORK_STATUS=0
	 else
	 	# check ethernet devices
	 	ETH_UP=0
	 	for i in `ifconfig -a | grep -e eth | awk '{print $1}'`
	 	do
			echo -n "	Checking device $i ..."
			IPaddr=`ifconfig $i | grep 'inet addr' | sed 's/.*inet addr:\(.*\).*Bcast:.*/\1/'`
			if [ "$IPaddr"x == "x" ]
			then
				ECHO_WARN " does not seem to have an IP addresss"
			else
				ETH_UP=1
	 			echo " using IP address $IPaddr"
	 			INHOSTS=`grep $IPaddr /etc/hosts`
	 			if [ $? == 1 ]
	 			then
	 				NETWORK_STATUS=0
	 				echo "		does not have an entry in /etc/hosts for its IP address $IPaddr"
	 			fi
	 		fi
	 	done
	 	if [ $ETH_UP == 0 ]
	 	then
	 		echo "	There seems to be no ethernet devices up."
	 		NETWORK_STATUS=0
	 	fi
	 	echo -n "	Checking loopback ..."
	 	# check loopback device
 		IPaddr=127.0.0.1
		INHOSTS=`grep $IPaddr /etc/hosts`
 		if [ $? == 1 ]
 		then
 			echo " does not have an loopback entry in /etc/hosts"
 			NETWORK_STATUS=0
 		else
 			echo " entry found"
 		fi
 		echo -n "	Checking localhost ..."
 		# check localhost entry
		
		grep 'localhost[ 	]' /etc/hosts 1>/dev/null 2>/dev/null
 		if [ $? == 1 ]
 		then
 			echo " does not have a localhost entry in /etc/hosts"
 			NETWORK_STATUS=0
 		else
 			IPaddr=`grep 'localhost[ 	]' /etc/hosts | awk '{print $1}'`
 			echo " mapped to $IPaddr"
 		fi	 	
 			 	
	 fi
	 [ $NETWORK_STATUS == 1 ] && FECHO_OK Network || FECHO_NOK Network
}

Check_MySQL()
{	
	if [ -L /etc/my.cnf ]
	then
		ls -l /etc/my.cnf 1>/dev/null
		ListMyCnf=$?
		ls -Ll /etc/my.cnf 1>/dev/null 2>/dev/null
		DerefListMyCnf=$?
		if [ $ListMyCnf == 0 -a $DerefListMyCnf == 2 ]
		then
			echo "	The MySQL configuration file /etc/my.cnf is a sym link that points nowhere"
			MYSQL_STATUS=0
		fi	
	fi
	
	USER=root
	PASSWORD=sunshine
	
	# check if mysqld running
	QUERY_RESP=`/usr/bin/mysqladmin -u$USER -p$PASSWORD ping 2>&1`
	if [ ! $? == 0 ]
	then
		if [ $INTERACTIVE == 1 ]
		then
			echo "	Could not connect to local MySQL server with default user and password."
			echo "------------------------------------------------------------------------"
			echo "Would you like to specify a username and password with which to connect?"
			read RESP
			if [ $RESP == "yes" ]
			then
				echo "Please enter a username:"
				read USER
				echo "Please enter a password:"
				read PASSWORD
				echo "------------------------------------------------------------------------"
			
				QUERY_RESP=`/usr/bin/mysqladmin -u$USER -p$PASSWORD ping 2>&1`
				if [ ! $? = 0 ]
				then
					echo "	Could not connect to local MySQL server."
					echo "	Please check that the MySQL service is running and that"
					echo "	root user has password 'sunshine' and localhost access. "
					MYSQL_STATUS=0
				fi
			else
				MYSQL_STATUS=0
			fi
		else
			MYSQL_STATUS=0
		fi		
	fi
	
	# check if access allowed
	FAULT_STR="Access denied"
	echo $QUERY_RESP | grep "$FAULT_STR" &> /dev/null
	if [ $? = 0 ] # found fault string
	then
		echo "	Could not connect to local MySQL server."
		echo "	Please change the root user password to 'sunshine'"
		echo "	and verify root user and localhost access. "
		MYSQL_STATUS=0
	fi
	[ $MYSQL_STATUS == 1 ] && FECHO_OK MySQL || FECHO_NOK MySQL
}	

Check_IQLicense()
{
	if [ $MYSQL_STATUS == 0 ]
	then
		echo "	Need MySQL server to be running"
		LICENSE_STATUS=0
	fi
	LIC_FILE="/opt/ineoquest/ivms-default/license/ivms_licsrvrc"
	if [ -e $LIC_FILE ]
	then
		pushd /opt/ineoquest/ivms-default 1>/dev/null
			./IQLicenseVerifier -vd
			grep "License File is NOT Valid" verifierlog.txt 1>/dev/null
			INVALID=$?
			if [ $INVALID == 0 ]
			then
				echo "	Your license file is not valid."
				UNIX_SEC=`date '+%s'`
				mv -f  $LIC_FILE $LIC_FILE.$UNIX_SEC
				echo -n "	" 
				./IQLicenseVerifier -i
				mv -f  $LIC_FILE.$UNIX_SEC  $LIC_FILE
				LICENSE_STATUS=0
			fi
		popd 1>/dev/null
	else
		echo "	You do not have a IQ License file at $LIC_FILE."
		FECHO_NOK License
		return 2
	fi
	[ $LICENSE_STATUS == 1 ] && FECHO_OK License || FECHO_NOK License
}

Check_Disk()
{
	perc_thresh=0.85
	if [ "`df | grep 'mysql$'`"x == "x" ]
	then
		echo "	Database on root partition"
		perc_used=`df -P | grep '/$' | awk '{print $3 / $2}'`
		amnt_used=`df -Pm | grep '/$' | awk '{print $3 / 1024}'`
	else
		echo "	Database on non-root partition"
		perc_used=`df -P | grep 'mysql$' | awk '{print $3 / $2}'`
		amnt_used=`df -Pm | grep 'mysql$' | awk '{print $3 / 1024}'`
	fi
	result=`expr $perc_used \> $perc_thresh`
	if [ $result == 1 ]
	then
		echo "	Disk usage is $amnt_used GB, `echo "$perc_used * 100" | bc`%, which is greater than threshold `echo "$perc_thresh* 100" | bc`%"
		echo "	This may not be good."
	else
		echo "	Disk usage is $amnt_used GB, `echo "$perc_used * 100" | bc`%"
	fi
	[ $DISK_STATUS == 1 ] && FECHO_OK Disk || FECHO_WARN Disk
}

Check_IQGuardian()
{
	IQGUARDIAN_STATUS=1
	NUM_HTTPD=`ps auxww | grep '/opt/ineoquest/ivms-default/apache/bin/httpd' | grep -v grep | wc -l`
	echo "	$NUM_HTTPD http daemons running"
	if [ $NUM_HTTPD == 0 ]
	then 
		IQGUARDIAN_STATUS=0
	fi
	[ $IQGUARDIAN_STATUS == 1 ] && FECHO_OK IQGuardian || FECHO_NOK IQGuardian
}

Check_iVMS()
{
	iVMS_STATUS=1
	for service in IQSyslogParser IQSyslogXfer IQTrapEventHandler IQUploadServer IQVMSState IQNBActivityProcessor IQNBAlarmProcessor IQNBMessageQueue IQNBSnmpAgent IQReportGenerator IQStateChangeHandler IQWatchDog IQCaseManager IQCommManager IQDataProcessor IQDBCleanupScheduler IQEmailNotifier IQEventProcessor IQGroupState IQMonitorState IQDataCube IQDataAggregator IQMediaState
	do
		if [ -e /opt/ineoquest/ivms-default/logs/ServiceWatch/$service ]
		then
 			if [ `ls -s /opt/ineoquest/ivms-default/logs/ServiceWatch/$service | awk '{print $1}'` != "0" ]
			then
				ECHO_WARN "	$service service may have been restarted by ServiceWach"
				iVMS_STATUS=0
			fi
		fi
	done
	[ $iVMS_STATUS == 1 ] && FECHO_OK iVMS || FECHO_NOK iVMS
}

Check_Date()
{
	# for more info see http://www.wikihow.com/Change-the-Timezone-in-Linux
	echo "	Current date is `date`"
	if [ $INTERACTIVE == 1 ]
	then
		source /etc/sysconfig/clock
		echo "The system time is set to zone region $ZONE."
		echo "Do you wish to change this? [yes,no]"
		read RESP
		if [ "$RESP" == "yes" ]
		then
			system-config-time
			echo "	Current date is `date`"
		else
			echo "Leaving system timezone alone."
		fi
	fi
}

echo "Checking OS"
Check_OS

echo "Checking Network"
Check_Network

echo "Checking MySQL"
Check_MySQL

echo "Checking IQ License"
Check_IQLicense

echo "Checking Disk"
Check_Disk

echo "Checking IQGuardian Service"
Check_IQGuardian

echo "Checking iVMS Service info"
Check_iVMS

echo "Checking Date"
Check_Date


