#!/bin/bash

# IPv4 calculator: prints network details for an IP address given either
# with a CIDR suffix (192.168.0.1/24) or with a netmask (192.168.0.1 255.255.255.0).
# Pure bash, no external tools required.

# global variables

regex_octet="(25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9][0-9]|[0-9])"
regex_ip="$regex_octet(\.$regex_octet){3}"
regex_cidr="(3[0-2]|[1-2][0-9]|[0-9])"

# helper functions

# dotted decimal -> 32-bit integer (sets: int)
function_ip2int()
{

	local o1 o2 o3 o4
	IFS=. read -r o1 o2 o3 o4 <<< "$1"
	int=$(( (o1 << 24) | (o2 << 16) | (o3 << 8) | o4 ))

}

# 32-bit integer -> dotted decimal (sets: dec)
function_int2ip()
{

	dec="$(( ($1 >> 24) & 255 )).$(( ($1 >> 16) & 255 )).$(( ($1 >> 8) & 255 )).$(( $1 & 255 ))"

}

# prefix length -> 32-bit netmask integer (sets: prefix_mask)
function_prefix2int()
{

	prefix_mask=$(( (0xFFFFFFFF << (32 - $1)) & 0xFFFFFFFF ))

}

# succeeds if $ip_int lies within network $1 with prefix length $2
function_in_net()
{

	function_ip2int "$1"
	function_prefix2int "$2"
	(( (ip_int & prefix_mask) == int ))

}

# main functions

# validate arguments and set ip, ip_int, mask_int and cidr
function_parse()
{

	if [[ $# -eq 1 && $1 =~ ^$regex_ip/$regex_cidr$ ]]
	then
		ip=${1%/*}
		cidr=${1#*/}
		function_prefix2int "$cidr"
		mask_int=$prefix_mask
	elif [[ $# -eq 2 && $1 =~ ^$regex_ip$ && $2 =~ ^$regex_ip$ ]]
	then
		ip=$1
		function_ip2int "$2"
		mask_int=$int

		# a valid netmask is a block of ones followed only by zeros,
		# i.e. its inverted value plus one must be a power of two
		local inverted=$(( ~mask_int & 0xFFFFFFFF ))
		if (( (inverted & (inverted + 1)) != 0 ))
		then
			function_help
			exit 1
		fi

		cidr=32
		for (( i = inverted; i > 0; i >>= 1 )); do
			(( cidr-- ))
		done
	else
		function_help
		exit 1
	fi

	function_ip2int "$ip"
	ip_int=$int

}

function_class()
{

	local octet1=${ip%%.*}

	if   (( octet1 < 128 )); then class=A
	elif (( octet1 < 192 )); then class=B
	elif (( octet1 < 224 )); then class=C
	elif (( octet1 < 240 )); then class=D
	else                          class=E
	fi

}

function_use()
{

	if   (( ip_int == 0xFFFFFFFF ));       then use="Broadcast"
	elif (( ip_int == 0x7F000001 ));       then use="Localhost"
	elif function_in_net 127.0.0.0 8;      then use="Loopback"
	elif function_in_net 10.0.0.0 8 ||
	     function_in_net 172.16.0.0 12 ||
	     function_in_net 192.168.0.0 16;   then use="Private"
	elif function_in_net 100.64.0.0 10;    then use="Shared (CGNAT)"
	elif function_in_net 169.254.0.0 16;   then use="Link-Local"
	elif function_in_net 0.0.0.0 8;        then use="This Network"
	elif function_in_net 224.0.0.0 4;      then use="Multicast"
	elif function_in_net 240.0.0.0 4;      then use="Reserved"
	else                                        use="Public"
	fi

}

function_calculate()
{

	function_int2ip "$mask_int"
	mask=$dec

	wildcard_int=$(( ~mask_int & 0xFFFFFFFF ))
	function_int2ip "$wildcard_int"
	wildcard=$dec

	net_addr_int=$(( ip_int & mask_int ))
	function_int2ip "$net_addr_int"
	net_addr=$dec

	broadcast_int=$(( net_addr_int | wildcard_int ))
	function_int2ip "$broadcast_int"
	broadcast=$dec

	ip_number=$(( wildcard_int + 1 ))

	# /31 (point-to-point, RFC 3021) and /32 have no network/broadcast address
	if (( cidr == 32 ))
	then
		host_number=1
	elif (( cidr == 31 ))
	then
		host_number=2
	else
		host_number=$(( ip_number - 2 ))
	fi

	if (( cidr >= 31 ))
	then
		function_int2ip "$net_addr_int"
		host_start=$dec
		function_int2ip "$broadcast_int"
		host_end=$dec
	else
		function_int2ip $(( net_addr_int + 1 ))
		host_start=$dec
		function_int2ip $(( broadcast_int - 1 ))
		host_end=$dec
	fi

}

# graphical functions

# pad a value to the width of the output box
function_space()
{

	local width=$(( 16 - ${#1} ))
	(( width < 0 )) && width=0
	printf '%*s' "$width" ""

}

function_header()
{

	echo ""
	echo "#################################################"
	echo "#                                               #"
	echo "#                 IP Calculator                 #"
	echo "#                                               #"
	echo "#                       by                      #"
	echo "#                                               #"
	echo "#                Owen Trafalgar                 #"
	echo "#                                               #"

}

function_help()
{

	function_header
	echo "#################################################"
	echo "#                                               #"
	echo "# syntax:                                       #"
	echo "#                                               #"
	echo "# ./ipcalc.sh [ip-address]/[cidr]               #"
	echo "# ./ipcalc.sh 192.168.0.1/24                    #"
	echo "#                                               #"
	echo "# or                                            #"
	echo "#                                               #"
	echo "# ./ipcalc.sh [ip-address] [netmask]            #"
	echo "# ./ipcalc.sh 192.168.0.1 255.255.255.0         #"
	echo "#                                               #"
	echo "#################################################"
	echo ""

}

function_output()
{

	function_header
	echo "#################################################"
	echo "#                                               #"
	echo "# IP-Address:                   $ip$(function_space "$ip")#"
	echo "# IP-Class:                     $class$(function_space "$class")#"
	echo "# Use Case:                     $use$(function_space "$use")#"
	echo "# Netmask:                      $mask$(function_space "$mask")#"
	echo "# CIDR Suffix:                  $cidr$(function_space "$cidr")#"
	echo "# Wildcard:                     $wildcard$(function_space "$wildcard")#"
	echo "# Network Address:              $net_addr$(function_space "$net_addr")#"
	echo "# Broadcast:                    $broadcast$(function_space "$broadcast")#"
	echo "# Number of IP-Addresses:       $ip_number$(function_space "$ip_number")#"
	echo "# Number of possible Hosts:     $host_number$(function_space "$host_number")#"
	echo "# Host IP Start:                $host_start$(function_space "$host_start")#"
	echo "# Host IP End:                  $host_end$(function_space "$host_end")#"
	echo "#                                               #"
	echo "#################################################"
	echo ""

}

function_parse "$@"
function_class
function_use
function_calculate
function_output
