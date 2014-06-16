#!/bin/sh

## MIT License:

## Copyright (C) 2014 blufro93

## Permission is hereby granted, free of charge, to any person obtaining a copy
## of this software and associated documentation files (the "Software"), to deal
## in the Software without restriction, including without limitation the rights
## to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
## copies of the Software, and to permit persons to whom the Software is
## furnished to do so, subject to the following conditions:

## The above copyright notice and this permission notice shall be included in
## all copies or substantial portions of the Software.

## THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
## IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
## FITNESS FOR A PARTICULAR PURPOSE AND NONNFRINGEMENT. IN NO EVENT SHALL THE
## AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
## LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
## OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
## SOFTWARE.

## first, uninstall ssh server
apt-get -y remove dropbear

## update our repositories
apt-get -y update

## upgrade to latest
apt-get -y upgrade

## install ca-certificates
apt-get -y install ca-certificates

## setup our /etc/network/interfaces file so that
## eth1 (our USB NIC) will serve as a gateway
network_interfaces="auto lo
iface lo inet loopback

#Onboard NIC connecting to the Internet
auto eth0
iface eth0 inet dhcp

#USB NIC serving as internal gateway
auto eth1
iface eth1 inet static
address 192.168.50.1
netmask 255.255.255.0
network 192.168.50.0
broadcast 192.168.50.255"

echo "$network_interfaces" > /etc/network/interfaces

## restart networking
service networking stop && service networking start

## install and setup our dhcp server
apt-get -y install isc-dhcp-server

## make this dhcp server the authoritative one
sed -i "s/#authoritative/authoritative/g" /etc/dhcp/dhcpd.conf

## and setup the subnet at the end of the config file
## connected client will get an ip somewhere in 192.168.50.10 to 192.168.50.250
subnet_config="
subnet 192.168.50.0 netmask 255.255.255.0 {
range 192.168.50.10 192.168.50.250;
option broadcast-address 192.168.50.255; 
option routers 192.168.50.1;
default-lease-time 600;
max-lease-time 7200;
option domain-name "local";
option domain-name-servers 8.8.8.8, 8.8.4.4;
}"

echo "$subnet_config" >> /etc/dhcp/dhcpd.conf

## restart dhcp server
/etc/init.d/isc-dhcp-server restart

## install tor
apt-get -y install tor

## setup our torrc file 
torrc_text="
Log notice file /var/log/tor/notices.log
VirtualAddrNetwork 10.192.0.0/10
AutomapHostsSuffixes .onion,.exit
AutomapHostsOnResolve 1
TransPort 9040
TransListenAddress 192.168.50.1
DNSPort 53
DNSListenAddress 192.168.50.1"

echo "$torrc_text" >> /etc/tor/torrc

## setup IP forwarding
echo 1 > /proc/sys/net/ipv4/ip_forward
sed -i "s/#net.ipv4.ip_forward=1/net.ipv4.ip_forward=1/g" /etc/dhcp/dhcpd.conf

## install iptables
apt-get -y install iptables

## now, configure iptables to let the LAN connections communicate with the WAN
iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
## this forwards UDP traffic on port 53 from the USB NIC to be redirected to local port 53 (for DNS traffic)
iptables -t nat -A PREROUTING -i eth1 -p udp --dport 53 -j REDIRECT --to-ports 53
## this forwards all TCP traffic from the USB NIC to be redirected to local port 9040
iptables -t nat -A PREROUTING -i eth1 -p tcp --syn -j REDIRECT --to-ports 9040
## this blocks access from RFC 1918 subnets on your internet (eth0) interface as well as ICMP (ping) packets and ssh connections.
iptables -A INPUT -s 192.168.0.0/24 -i eth0 -j DROP
iptables -A INPUT -s 10.0.0.0/8 -i eth0 -j DROP
iptables -A INPUT -s 172.16.0.0/12 -i eth0 -j DROP
iptables -A INPUT -s 224.0.0.0/4 -i eth0 -j DROP
iptables -A INPUT -s 240.0.0.0/5 -i eth0 -j DROP
iptables -A INPUT -s 127.0.0.0/8 -i eth0 -j DROP
iptables -A INPUT -i eth0 -p tcp -m tcp --dport 22 -j DROP
iptables -A INPUT -i eth0 -p icmp -m icmp --icmp-type 8 -j DROP
## this blocks all udp traffic (except DNS)
iptables -A INPUT -p udp --sport 53 -j ACCEPT
iptables -A INPUT -p udp --dport 53 -j ACCEPT
iptables -A OUTPUT -p udp --sport 53 -j ACCEPT
iptables -A OUTPUT -p udp --dport 53 -j ACCEPT
iptables -A INPUT -p udp -j DROP
iptables -A OUTPUT -p udp -j DROP

## save off iptables rules to disk
iptables-save > /etc/iptables.up.rules

## create script which will restore iptables rules on boot
iptables_text="#!/bin/sh
#This script restores iptables upon reboot

iptables-restore < /etc/iptables.up.rules

exit 0"

echo "$iptables_text" > /etc/network/if-pre-up.d/iptables
chown root:root /etc/network/if-pre-up.d/iptables 
chmod +x /etc/network/if-pre-up.d/iptables 
chmod 755 /etc/network/if-pre-up.d/iptables

## start tor
service tor start

## and make tor run on boot
update-rc.d tor enable

## now make the root file system read-only (from http://blog.pi3g.com/2014/04/make-raspbian-system-read-only/ )

## install unionfs which will be used for our ramdisk file system
apt-get -y install unionfs-fuse

## create mount script
mount_script="#!/bin/sh
DIR=\$1
ROOT_MOUNT=\$(awk '\$2==\"/\" {print substr(\$4,1,2)}' < /etc/fstab)

if [ \$ROOT_MOUNT = \"rw\" ]
then
	/bin/mount --bind \${DIR}_org \${DIR}
else
	/bin/mount -t tmpfs ramdisk \${DIR}_rw
	/usr/bin/unionfs-fuse -o cow,allow_other,suid,dev,nonempty \${DIR}_rw=RW:\${DIR}_org=RO \${DIR}
fi"

echo "$mount_script" > /usr/local/bin/mount_unionfs
chmod +x /usr/local/bin/mount_unionfs

## update fstab

fstab="proc            /proc           proc    defaults          0       0
/dev/mmcblk0p1  /boot           vfat    ro                0       2
/dev/mmcblk0p2  /               ext4    ro,noatime        0       1
mount_unionfs   /etc            fuse    defaults          0       0
mount_unionfs   /var            fuse    defaults          0       0
none            /tmp            tmpfs   defaults          0       0"

echo "$fstab" > /etc/fstab

## backup the /var and /etc directories 

cp -al /etc /etc_org
mv /var /var_org
mkdir /etc_rw
mkdir /var /var_rw

## restart and we're done!
shutdown -r -t now