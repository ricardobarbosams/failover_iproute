#!/usr/bin/env bash
 
#*********************************************************************
#       Configuration
#*********************************************************************
declare -a GATEWAYS
GATEWAYS[0]="192.168.1.1"	# Provider 01
GATEWAYS[1]="192.168.2.1"	# Provider 02

#|   URI                                 		            | Response                 |
#|------------------------------------------------------|--------------------------|	
#| http://network-test.debian.org/nm   		    	        | NetworkManager is online |
#| https://fedoraproject.org/static/hotspot.txt      	  | OK		       	           |
#| http://nmcheck.gnome.org/check_network_status.txt  	| NetworkManager is online |
#| https://www.pkgbuild.com/check_network_status.txt  	| NetworkManager is online |
#
#*********************************************************************

CMD_IP=$( which ip )

check_availability_connectivity() {
	retval="false"
	TEST_1=$( curl -s --head http://network-test.debian.org/nm | head -1 | awk '{print $2}' )
	TEST_2=$( curl -s --head https://fedoraproject.org/static/hotspot.txt | head -1 | awk '{print $2}')
	TEST_3=$( curl -s --head http://nmcheck.gnome.org/check_network_status.txt | head -1 | awk '{print $2}')
	TEST_4=$( curl -s --head https://www.pkgbuild.com/check_network_status.txt | head -1 | awk '{print $2}')
	if [ "$TEST_1" == "200" ] && [ "$TEST_2" == "200" ] && [ "$TEST_3" == "200" ] && [ "$TEST_4" == "200" ]
	then
		retval="true"
	fi
	echo "$retval"
}

#-------------------------------------------------------
[ $( whoami) != "root" ] && echo "Failover script must be run as root!" && exit 1
[ -z ${CMD_IP} ] && echo "The iproute command does not exist" && exit 1
#-------------------------------------------------------

RESULT=$( check_availability_connectivity )

if [ "$RESULT" == "false" ];
then
	CURRENT_GATEWAY=$( ip route show | grep default | awk '{ print $3 }' )
	LOG_TIME=$( date +%b' '%d' '%T )
	for i in "${GATEWAYS[@]}"
	do
		if [ "$CURRENT_GATEWAY" != "$i" ];
		then
			echo $CMD_IP route del default
			echo $CMD_IP route add default via $i
			echo $CMD_IP route flush cache
			echo "$LOG_TIME - Switched Gateway from $CURRENT_GATEWAY to IP $i"
		fi
	done
fi
