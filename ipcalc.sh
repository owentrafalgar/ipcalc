#!/bin/bash

# global variables

regex_start="^"
regex_end="$"
regex_ip="(([0-9])|([1-9][0-9])|(1[0-9][0-9])|(2[0-4][0-9])|25[0-5])\.(([0-9])|([1-9][0-9])|(1[0-9][0-9])|(2[0-4][0-9])|25[0-5])\.(([0-9])|([1-9][0-9])|(1[0-9][0-9])|(2[0-4][0-9])|25[0-5])\.(([0-9])|([1-9][0-9])|(1[0-9][0-9])|(2[0-4][0-9])|25[0-5])"
regex_cidr_slash="\/"
regex_cidr="(([0-9])|([1-2][0-9])|(3[0-2]))"
regex_mask="(((255\.){3}(255|254|252|248|240|224|192|128+))|((255\.){2}(255|254|252|248|240|224|192|128|0+)\.0)|((255\.)(255|254|252|248|240|224|192|128|0+)(\.0+){2})|((255|254|252|248|240|224|192|128|0+)(\.0+){3}))"

# helper functions

function_split()
{

	octet1=$(echo $1 | cut -d"." -f1)
	octet2=$(echo $1 | cut -d"." -f2)
	octet3=$(echo $1 | cut -d"." -f3)
	octet4=$(echo $1 | cut -d"." -f4)

}

function_dec2bin()
{

	function_split $1
	octet_bin1=$(printf "%08d\n" $(echo "obase=2; $((octet1))" | bc))
	octet_bin2=$(printf "%08d\n" $(echo "obase=2; $((octet2))" | bc))
	octet_bin3=$(printf "%08d\n" $(echo "obase=2; $((octet3))" | bc))
	octet_bin4=$(printf "%08d\n" $(echo "obase=2; $((octet4))" | bc))

}

function_bin2dec()
{

	octet_bin1=$(echo $1 | cut -c-8)
	octet_bin2=$(echo $1 | cut -c9-16)
	octet_bin3=$(echo $1 | cut -c17-24)
	octet_bin4=$(echo $1 | cut -c25-32)
	octet_dec1=$(echo "$((2#$octet_bin1))")
	octet_dec2=$(echo "$((2#$octet_bin2))")
	octet_dec3=$(echo "$((2#$octet_bin3))")
	octet_dec4=$(echo "$((2#$octet_bin4))")
	dec=$(echo $octet_dec1.$octet_dec2.$octet_dec3.$octet_dec4)

}

function_dec2bit()
{

	function_dec2bin $1
	octet_bit1=$(echo $octet_bin1 | grep -o '1' | grep -c .)
	octet_bit2=$(echo $octet_bin2 | grep -o '1' | grep -c .)
	octet_bit3=$(echo $octet_bin3 | grep -o '1' | grep -c .)
	octet_bit4=$(echo $octet_bin4 | grep -o '1' | grep -c .)
	bit=$(echo $(( octet_bit1 + octet_bit2 + octet_bit3 + octet_bit4 ))| bc)

}

function_bit2dec()
{

	max_bit=32
	zeros=$(echo $(( max_bit - cidr )) | bc)
	bin=$(printf %$(echo $1)s |tr " " "1")$(printf %$(echo $zeros)s |tr " " "0")
	function_bin2dec $bin

}

# main functions

function_ip()
{

	if [[ $1 =~ $regex_start$regex_ip$regex_cidr_slash$regex_cidr$regex_end ]] || [[ $1 =~ $regex_start$regex_ip$regex_end ]]
	then
		ip=$(echo $1 | cut -d"/" -f1)
	else
		function_help
		exit 1
	fi

}

function_mask()
{

	if [[ $2 =~ $regex_start$regex_mask$regex_end ]]
	then
		mask=$2
	elif [[ $1 =~ $regex_start$regex_ip$regex_cidr_slash$regex_cidr$regex_end ]]
	then
		cidr=$(echo $1 | cut -d"/" -f2)
		function_bit2dec $cidr
		mask=$dec
	else
		function_help
		exit 1
	fi

}

function_cidr()
{

	if [[ $1 =~ $regex_start$regex_ip$regex_cidr_slash$regex_cidr$regex_end ]]
	then
		cidr=$(echo $1 | cut -d"/" -f2)
	elif [[ $2 =~ $regex_start$regex_mask$regex_end ]]
	then
		function_dec2bit $2
		cidr=$bit
	else
		function_help
		exit 1
	fi

}

function_wildcard()
{

	function_split $1
	wildcard_octet1=$(echo $(( 255 - octet1 ))| bc)
	wildcard_octet2=$(echo $(( 255 - octet2 ))| bc)
	wildcard_octet3=$(echo $(( 255 - octet3 ))| bc)
	wildcard_octet4=$(echo $(( 255 - octet4 ))| bc)
	wildcard=$(echo $wildcard_octet1.$wildcard_octet2.$wildcard_octet3.$wildcard_octet4)

}

function_net_addr()
{

	function_dec2bin $1
	ip_bin=$(echo $octet_bin1$octet_bin2$octet_bin3$octet_bin4)

	function_dec2bin $2
	mask_bin=$(echo $octet_bin1$octet_bin2$octet_bin3$octet_bin4)

	for (( i=0; i<32; i++ )); do
		net_addr_arr[$i+1]=$(echo $(( ${ip_bin:$i:1} && ${mask_bin:$i:1} )) )
	done

	net_addr_bin=$(echo ${net_addr_arr[*]} | sed 's/ //g')
	function_bin2dec $net_addr_bin
	net_addr=$dec

}

function_broadcast()
{

	function_dec2bin $1
	ip_bin=$(echo $octet_bin1$octet_bin2$octet_bin3$octet_bin4)

	function_dec2bin $2
	mask_bin=$(echo $octet_bin1$octet_bin2$octet_bin3$octet_bin4)

	for (( i=0; i<32; i++ )); do
		broadcast_arr[$i+1]=$(echo $(( ${ip_bin:$i:1} || ${mask_bin:$i:1} )) )
	done

	broadcast_bin=$(echo ${broadcast_arr[*]} | sed 's/ //g')
	function_bin2dec $broadcast_bin
	broadcast=$dec

}

function_ip_number()
{

	function_dec2bin $1
	mask_bin=$(echo $octet_bin1$octet_bin2$octet_bin3$octet_bin4)
	mask_zeros=$(echo $mask_bin | grep -o '0' | grep -c .)
	ip_number=$(echo 2 ^ $mask_zeros | bc)

}

function_host_number()
{

	if [[ $2 = 31 ]]
	then
		host_number=2
	elif [[ $2 = 32 ]]
	then
		host_number=1
	else
		host_number=$(echo $1 - 2 | bc)
	fi

}

function_host_start()
{

	if [[ $2 -ge 31 ]]
	then
		host_start=$1
	else
		net_addr_octet4=$(echo $1 | cut -d"." -f4)
		host_start_octet4=$(echo $net_addr_octet4 + 1 | bc)
		host_start=$(echo $(echo $1 | cut -d"." -f-3).$host_start_octet4)
	fi

}

function_host_end()
{

	if [[ $2 -ge 31 ]]
	then
	        host_end=$1
	else
	        broadcast_octet4=$(echo $1 | cut -d"." -f4)
	        host_end_octet4=$(echo $broadcast_octet4 - 1 | bc)
	        host_end=$(echo $(echo $1 | cut -d"." -f-3).$host_end_octet4)
	fi

}

# graphical functions

function_space()
{

	printf %$(echo $(echo 17 - $(echo $1 | wc -c)| bc))s |tr " " " "

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
	echo "#               Marcus Kindermann               #"
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
	echo "# IP-Address:                   $ip$(function_space $ip)#"
	echo "# Netmask:                      $mask$(function_space $mask)#"
	echo "# CIDR Suffix:                  $cidr$(function_space $cidr)#"
	echo "# Wildcard:                     $wildcard$(function_space $wildcard)#"
	echo "# Network Address:              $net_addr$(function_space $net_addr)#"
	echo "# Broadcast:                    $broadcast$(function_space $broadcast)#"
	echo "# Number of IP-Addresses:       $ip_number$(function_space $ip_number)#"
	echo "# Number of possible Hosts:     $host_number$(function_space $host_number)#"
	echo "# Host IP Start:                $host_start$(function_space $host_start)#"
	echo "# Host IP End:                  $host_end$(function_space $host_end)#"
	echo "#                                               #"
	echo "#################################################"
	echo ""

}

function_ip $1
function_mask $1 $2
function_cidr $1 $2
function_wildcard $mask
function_net_addr $ip $mask
function_broadcast $ip $wildcard
function_ip_number $mask
function_host_number $ip_number $cidr
function_host_start $net_addr $cidr
function_host_end $broadcast $cidr

function_output
