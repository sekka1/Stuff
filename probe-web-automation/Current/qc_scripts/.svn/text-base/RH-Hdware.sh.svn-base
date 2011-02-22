#!/bin/bash

rm /tmp/sys-output

echo "PCI Info" >>  /tmp/sys-output
lspci >> /tmp/sys-output

echo "Memory Info" >>  /tmp/sys-output
dmesg | grep -i memory >>  /tmp/sys-output

echo "CPU Info" >> /tmp/sys-output
cat /proc/cpuinfo  >>  /tmp/sys-output

echo "HDD Info" >>  /tmp/sys-output
fdisk -l >>  /tmp/sys-output

#echo "/n " >>  /tmp/sys-output
#fdisk -l /dev/sdb* >> /tmp/sys-output

echo "/n" >>  /tmp/sys-output
fdisk -l /dev/hda* >> /tmp/sys-output

#echo "Package Info" >>  /tmp/sys-output
#rpm -qa >> /tmp/sys-output

echo "MySQL Package Info" >>  /tmp/sys-output
rpm -qa mysql* >> /tmp/sys-output

echo "IVMS Package Info" >>  /tmp/sys-output
rpm -qa ineoquest* >> /tmp/sys-output

echo "Relese Info" >> /tmp/sys-output
cat /etc/*-release >> /tmp/sys-output

echo "Platform Info" >> /tmp/sys-output
uname -a >> /tmp/sys-output

echo "Please view sys-output file in /tmp/sys-output directory for system output"
