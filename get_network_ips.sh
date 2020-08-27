#!/bin/bash

if ! type nmap &> /dev/null; then
  test -e /etc/debian_version && sudo apt install -y nmap || sudo yum install -y nmap
fi

function get_ips_and_macs {
  lan_ip=$( ip route | awk '/default/ { split( $3, a, "." ); print a[1]"."a[2]"."a[3] }' )	  # get lan ip like 192.168.0

  sudo nmap -sn -PO ${lan_ip}.1-255								| # ping scan for a ip range 
  grep -Eo '([0-9]{1,3}\.){3}[0-9]{1,3}|[[:xdigit:]:]{6,}' 					| # filter only IP and MAC address
  awk 'BEGIN{ m=0 } { if ( $1 ~ /^[[:digit:].]{3,}/ ) m++; print m, $0 }'			| # create a relationship between IP and MAC 
  awk '{ a[$1] = a[$1] FS substr( $0, index( $0,$2 ) ) } END{ for( i in a ) print i a[i] }'	| # put ID, IP and MAC on same line
  awk '{ print $2, $3 }'									  # print IP and Mac
} 

function get_mac_of_default_gateway_interface {
  ifconfig $( route -n | awk '/^0.0.0.0/ { print $NF }' )		| # get network info of interface coonected to default gateway
  sed -n '/inet /p; /ether /p'						| # print lines with inet and ether string
  awk 'ORS=" " { print $2 }' 						  # print ip and mac in the same line
}

function join_ips_and_macs_with_mac_of_default_gw {
  { get_ips_and_macs; get_mac_of_default_gateway_interface; }					| # join output of two functions
  awk '$2!=""?$2:$2="_"'									| # fill IPs without MAC with _ 
  awk '{ a[$1] = a[$1] FS substr( $0, index( $0,$2 ) ) } END{ for( i in a ) print i a[i] }'	| # put elements with same IP on the same line
  awk '{ print $1, toupper( $NF ) }'								  # print IP and Mac in uppercase
}	

join_ips_and_macs_with_mac_of_default_gw				| # call function
sort -V									| # natural sort numbers with text
# creates a new column - device alias based in MAC
awk '$2=="68:FF:7B:6B:5C:D5"?$0=$0" Router":$0'				| # Router
awk '$2=="28:16:AD:EC:0F:54"?$0=$0" Laptop":$0'				| # Laptop 
awk '$2=="DC:90:88:2E:8C:12"?$0=$0" Mobile":$0'				| # Mobile
awk '$2=="40:CD:7A:25:3D:71"?$0=$0" TV":$0'				| # TV
awk '$2=="DC:A6:32:3C:4C:C0"?$0=$0" Raspberry":$0'			| # Raspberry
awk '$2=="D0:C5:D3:9A:52:3D"?$0=$0" \033[33;1mGuest-Out\033[m":$0'	| # Guest Out
nl									| # add numbers to lines
cat <( echo "Id IP Mac DeviceAlias" ) -					| # append header to stdout
column -t								  # format stdout
