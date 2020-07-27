#!/bin/bash

if ! type nmap &> /dev/null; then
  test -e /etc/debian_version && sudo apt install -y nmap || sudo yum install -y nmap
fi

function get_ips_and_macs {
  lan_ip=$( ip route | awk '/default/ { split( $3, a, "." ); print a[1]"."a[2]"."a[3] }' )	  # get lan ip like 192.168.0

  sudo nmap -sn -PO ${lan_ip}.1-255								| # ping scan for a ip range 
  grep -Eo '([0-9]{1,3}\.){3}[0-9]{1,3}|[[:xdigit:]:]{6,}' 					| # filter only IP and MAC address
  awk 'BEGIN{ m=0 } { if ( $1 ~ /^[[:digit:].]{3,}/ ) m++; print m, $0 }'			| # create a relationship between IP and MAC 
  awk '{ a[$1] = a[$1] FS substr( $0, index( $0,$2 ) ) } END{ for( i in a ) print i a[i] }'	  # print IP and MAC on same line
} 

get_ips_and_macs							|
sort -k2n								| # numeric sort by column 2 IPs
awk '$3!=""?$3:$3="_"'							| # fill IPs without MAC with _ 
awk '$3=="68:FF:7B:6B:5C:D5"?$0=$0" Router":$0'				| # Router
awk '$3=="DC:90:88:2E:8C:12"?$0=$0" Mobile":$0'				| # Mobile
awk '$3=="40:CD:7A:25:3D:71"?$0=$0" TV":$0'				| # TV
awk '$3=="DC:A6:32:3C:4C:C0"?$0=$0" Raspberry":$0'			| # Raspberry
awk '$3=="_"?$0=$0" Laptop":$0'						| # Laptop
awk '$3=="D0:33:11:35:B7:29"?$0=$0" \033[33;1mGuest-Out\033[m":$0'	| # Guest Out 
column -t								  # format stdout
