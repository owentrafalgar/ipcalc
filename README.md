# ipcalc

## a simple IPv4 calculator

This script calculates several values with the input
of IP-address and subnetmask or IP-address and CIDR.
see example below.

It is written in pure bash and needs no external tools.

### calculated values

- IP-Class (A-E)
- Use Case: Public, Private (RFC 1918), Loopback, Localhost, Link-Local,
  Shared (CGNAT, RFC 6598), This Network (0.0.0.0/8), Multicast,
  Reserved (240.0.0.0/4) and Broadcast (255.255.255.255)
- Netmask, CIDR suffix and wildcard mask
- Network address and broadcast address
- Number of IP-addresses and possible hosts
  (/31 and /32 are handled according to RFC 3021)
- First and last host IP

Invalid input (malformed IP-address, non-contiguous netmask, CIDR > 32,
or CIDR and netmask given at the same time) prints the syntax help and
exits with status 1.

### syntax:
```
#################################################
#                                               #
#                 IP Calculator                 #
#                                               #
#                       by                      #
#                                               #
#                Owen Trafalgar                 #
#                                               #
#################################################
#                                               #
# syntax:                                       #
#                                               #
# ./ipcalc.sh [ip-address]/[cidr]               #
# ./ipcalc.sh 192.168.0.1/24                    #
#                                               #
# or                                            #
#                                               #
# ./ipcalc.sh [ip-address] [netmask]            #
# ./ipcalc.sh 192.168.0.1 255.255.255.0         #
#                                               #
#################################################
```

### example
```
./ipcalc.sh 192.168.0.123/24

#################################################
#                                               #
#                 IP Calculator                 #
#                                               #
#                       by                      #
#                                               #
#                Owen Trafalgar                 #
#                                               #
#################################################
#                                               #
# IP-Address:                   192.168.0.123   #
# IP-Class:                     C               #
# Use Case:                     Private         #
# Netmask:                      255.255.255.0   #
# CIDR Suffix:                  24              #
# Wildcard:                     0.0.0.255       #
# Network Address:              192.168.0.0     #
# Broadcast:                    192.168.0.255   #
# Number of IP-Addresses:       256             #
# Number of possible Hosts:     254             #
# Host IP Start:                192.168.0.1     #
# Host IP End:                  192.168.0.254   #
#                                               #
#################################################
```

