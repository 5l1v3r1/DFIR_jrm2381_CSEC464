#!/bin/bash
#This script will collect forensic evidence

function findTime {

	echo "#########################"
	echo "####### Time Info #######"
	echo "#########################"

	curr=`date +%T`
	zn=`timedatectl | grep "zone" | cut -d":" -f2`
	uptm=`uptime -p`

	echo "Time: $curr"
	echo "Time Zone: $zn"
	echo "Computer Uptime: $uptm"
	echo " "
}


function findOpSys {
	echo "#########################"
        echo "######## OS Info ########"
        echo "#########################"

	build=`cat /etc/os-release | grep Pretty | cut -d"=" -f2`
	words=`cat /etc/lsb-release | grep ID | cut -d"=" -f2`
	kern=`uname -v`

	echo "OS Version: $build"
	echo "Typical Name: $words"
	echo "Kernel: $kern"
	echo " "
	echo " "
}


function findHardware {
	
	echo "#########################"
        echo "##### Hardware Info #####"
        echo "#########################"

	cpu_inf=`lscpu | grep "Model name:" | cut -d":" -f2 | awk '{$1=$1};1'`
	ram_inf=`awk '/^MemTotal:/{print $2}' /proc/meminfo`
	hard_drives=`lsblk | grep disk | cut -d" " -f1`
	systems=`df -h`

	echo "CPU Type: $cpu_inf"
	echo "RAM: $ram_inf"
	echo "HDDs: $hard_drives"
	echo "File Systems: "
	echo 		$systems
	echo " "
	echo " "
}


function findDomain {
	echo "#########################"
        echo "###### Domain Info ######"
        echo "#########################"

	hn=`hostname`
	dom=`domainname`

	echo "Hostname: $hn"
	echo "Domain: $dom"
	echo " "
	echo " "
}


function findUsers {
	echo "#########################"
        echo "####### User Info #######"
        echo "#########################"
	
	for users in `getent passwd | cut -d":" -f1`
	do
		echo " "
		users=$users
		uid=`awk -F: -v u=$users '$1 == u {print $3}' /etc/passwd`
		gid=`awk -F: -v u=$users '$1 == u {print $4}' /etc/passwd`
		shl=`awk -F: -v u=$users '$1 == u {print $NF}' /etc/passwd`
		echo "User: $users"
		echo "UID: $uid"
		echo "GID: $gid"
		echo "Shell: $shl"
	done
	echo " "
	hist=`last`
	echo "History: $hist"
	echo " "
	echo " "
}


function findBootProgs {
	echo "#########################"
        echo "##### Start Up  Info ####"
        echo "#########################"

	start=`initctl list`
	echo "Services on Start: "
	echo "${start//,},"
	echo " "
	echo " "
}


function findCron {
	echo "#########################"
        echo "####### Cron Info #######"
        echo "#########################"

	crons=$(crontab -l 2>&1)
	echo "Cron jobs: ${crons//,},"
	echo " "
	echo " "
}


function findNetInfo {
	echo "#########################"
        echo "##### Network Info ######"
        echo "#########################"

	arp=`arp`
	macs=`ifconfig -a | awk '/^[a-z]/ {intfa=$1; mac=$NF; next } /inet addr:/ { print intfa, mac}'`
	route=`route`
	ips=`ip addr | awk '
    	/^[0-9]+:/ { 
        	sub(/:/,"",$2); iface=$2 }
    	/^[[:space:]]*inet / { 
        	split($2, a, "/") 
        	print iface" : "a[1] }'`

   
	dhcp=`journalctl | grep DHCPACK | grep -o '[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}' | tr '\n' ' ' | awk '{print $2}'`
	dns=`cat /etc/resolv.conf | grep nameserver`
	gateIP=`ip route`
	lstn=`netstat -tul4n`
	estb=`netstat -tul4a | grep ESTABLISHED`

	echo "ARP: ${arp//,},"
	echo "Interfaces: ${macs//,},"
	echo "Routing: "
	echo "${route//,},"
	echo "Interface IPs:"
	echo "${ips//,},"
	echo "DHCP Serv: $dhcp"
	echo "DNS Serv: $dns"
	echo "Gateways:"
	echo "${gateIP//,},"
	echo " "
	echo "Listening Services: $lstn//,},"
	echo " "
	echo "Established Connections: $estb//,},"
	echo " "
	echo " "
}


function findPrinterInfo {
	echo "#########################"
        echo "##### Printer Info ######"
        echo "#########################"

	prnts=`lpstat -p -d 2>&1`
	
	echo "Available Printers: "
	echo "${prnts//,},"
	echo " "
	echo " "
}


function findProcs {

	echo "#########################"
        echo "##### Process Info ######"
        echo "#########################"

    	for pid in `ps -A -o pid`   
    	do
        	processName=`ps -p $pid -o comm= 2>/dev/null`
        	processId=$pid 
        	processParent=`ps -o ppid= -p $pid 2>/dev/null`
        	processLocation=`readlink /proc/$pid/exe 2>/dev/null`

        	if [ -n "$processName" ]; then
            		echo "Process Name: ${processName//,}"
        	fi
        	if [ -n "$processId" ]; then
            		echo "Process ID: ${processId//,}"
        	fi
        	if [ -n "$processParent" ]; then
            		echo "Parent ID: ${processParent//}"
        	fi
        	if [ -n "$processLocation" ]; then
            		echo "Procces Location: ${processLocation//,}"
        	fi
        	echo " "
    	done

    	echo ","
    	echo " "
	echo " "
}


function findDrivers {
	echo "#########################"
        echo "##### Driver Info #######"
        echo "#########################"
	
	drvs=`lsmod`
	echo "${drvs//,},"
	echo " "
	echo " "
}


function findFiles {
	echo "#########################"
        echo "####### Files Info ######"
        echo "#########################"

	for usr in `ls /home/`
	do
		echo "Username: $usr"
		echo "Downloads: `ls /home/$usr/Downloads | tr '\n' ' '`"
		echo "Documents: `ls /home/$usr/Documents | tr '\n' ' '`"
	done

	echo " "
	echo " "
}


function findFirewallInfo {
	echo "#########################"
        echo "##### Firewall Info #####"
        echo "#########################"

	rules=`sudo iptables --list`
	echo "${rules//,},"
	echo " "
	echo " "
}


function findEditHistory {
	echo "#########################"
        echo "##### Modified Files ####"
        echo "#########################"

	eh=`ls -1t | head -15`
	echo "Last Edited Files: ${eh//,},"
	echo " "
	echo " "
}


function findAllServs {
	echo "#########################"
        echo "##### All Services ######"
        echo "#########################"

	servs=`service --status-all`
	echo "All Services: "
	echo "${servs//,},"
	echo " "
	echo " "
}
function main {
	findTime
	findOpSys
	findHardware
	findUsers
	findBootProgs
	findCron
	findNetInfo
	findPrinterInfo
	findProcs
	findDrivers
	findFiles
	findFirewallInfo
	findEditHistory
	findAllServs
}


main

main > out.csv

































