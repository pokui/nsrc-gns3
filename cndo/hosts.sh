#!/bin/bash -eu

cat <<EOS
# Use this file to replace your /etc/hosts, or append it to the end

127.0.0.1	localhost
::1     localhost ip6-localhost ip6-loopback
ff02::1 ip6-allnodes
ff02::2 ip6-allrouters

# Devices on management network
192.168.122.1		vtp.ws.nsrc.org apt.ws.nsrc.org gns3.ws.nsrc.org www.ws.nsrc.org gw.ws.nsrc.org
192.168.122.2		gi0-0.transit1.nren.ws.nsrc.org transit1.nren.ws.nsrc.org
2001:DB8:0:0::2		gi0-0.transit1.nren.ws.nsrc.org transit1.nren.ws.nsrc.org
192.168.122.3		gi0-0.transit2.nren.ws.nsrc.org transit2.nren.ws.nsrc.org
2001:DB8:0:0::3		gi0-0.transit2.nren.ws.nsrc.org transit2.nren.ws.nsrc.org
EOS

for campus in $(seq 1 6); do
cat <<EOS
192.168.122.$((10*campus))		srv1-oob.campus${campus}.ws.nsrc.org librenms.campus${campus}.ws.nsrc.org rt.campus${campus}.ws.nsrc.org nfsen.campus${campus}.ws.nsrc.org srv1-campus${campus}
EOS
for i in $(seq 1 6); do
cat <<EOS
192.168.122.$((10*campus+i))		host${i}-oob.campus${campus}.ws.nsrc.org host${i}-campus${campus}
EOS
done
done

cat <<EOS

192.168.122.250		noc.ws.nsrc.org librenms.ws.nsrc.org rt.ws.nsrc.org nfsen.ws.nsrc.org noc
192.168.122.251		ap1.ws.nsrc.org ap1
192.168.122.252		ap2.ws.nsrc.org ap2
192.168.122.253		sw.ws.nsrc.org sw
192.168.122.254		transit.nren.ws.nsrc.org

# Transit links
EOS
for campus in $(seq 1 6); do
cat <<EOS
100.68.0.$((campus*4-3))		gi0-${campus}.transit1.nren.ws.nsrc.org
2001:DB8:100:${campus}::	gi0-${campus}.transit1.nren.ws.nsrc.org
100.68.0.$((campus*4-2))		gi0-0.bdr1.campus${campus}.ws.nsrc.org
2001:DB8:100:${campus}::1	gi0-0.bdr1.campus${campus}.ws.nsrc.org
EOS
done
for campus in $(seq 1 6); do
cat <<EOS
100.68.0.$((campus*4-3+128))		gi0-${campus}.transit2.nren.ws.nsrc.org
2001:DB8:100:${campus+32}::	gi0-${campus}.transit2.nren.ws.nsrc.org
100.68.0.$((campus*4-2+128))		gi0-2.bdr1.campus${campus}.ws.nsrc.org
2001:DB8:100:${campus+32}::1	gi0-2.bdr1.campus${campus}.ws.nsrc.org
EOS
done

cat <<EOS
100.68.0.251		lo0.transit1.nren.ws.nsrc.org
2001:DB8:100:FF::251	lo0.transit1.nren.ws.nsrc.org
100.68.0.252		lo0.transit2.nren.ws.nsrc.org
2001:DB8:100:FF::252	lo0.transit2.nren.ws.nsrc.org
EOS

for campus in $(seq 1 6); do
cat <<EOS

# Campus ${campus}

100.68.${campus}.1		gi0-1.bdr1.campus${campus}.ws.nsrc.org bdr1.campus${campus}.ws.nsrc.org
2001:DB8:${campus}:0::1		gi0-1.bdr1.campus${campus}.ws.nsrc.org bdr1.campus${campus}.ws.nsrc.org
100.68.${campus}.2		gi0-0.core1.campus${campus}.ws.nsrc.org core1.campus${campus}.ws.nsrc.org
2001:DB8:${campus}:0::2		gi0-0.core1.campus${campus}.ws.nsrc.org core1.campus${campus}.ws.nsrc.org

100.68.${campus}.129		gi0-3.core1.campus${campus}.ws.nsrc.org
2001:DB8:${campus}:1::1		gi0-3.core1.campus${campus}.ws.nsrc.org
100.68.${campus}.130		srv1.campus${campus}.ws.nsrc.org
2001:DB8:${campus}:1::130	srv1.campus${campus}.ws.nsrc.org
EOS
for i in $(seq 1 6); do
cat <<EOS
100.68.${campus}.$((130+i))		host${i}.campus${campus}.ws.nsrc.org
2001:DB8:${campus}:1::$((130+i))	host${i}.campus${campus}.ws.nsrc.org
EOS
done

cat <<EOS

100.68.${campus}.241		lo0.bdr1.campus${campus}.ws.nsrc.org
2001:DB8:${campus}:2::241	lo0.bdr1.campus${campus}.ws.nsrc.org
100.68.${campus}.242		lo0.core1.campus${campus}.ws.nsrc.org
2001:DB8:${campus}:2::242	lo0.core1.campus${campus}.ws.nsrc.org

172.2${campus}.10.1		vlan10.core1.campus${campus}.ws.nsrc.org
2001:DB8:${campus}:10::1	vlan10.core1.campus${campus}.ws.nsrc.org
172.2${campus}.10.2		dist1-b1.campus${campus}.ws.nsrc.org
2001:DB8:${campus}:10::2	dist1-b1.campus${campus}.ws.nsrc.org
172.2${campus}.10.3		edge1-b1.campus${campus}.ws.nsrc.org
2001:DB8:${campus}:10::3	edge1-b1.campus${campus}.ws.nsrc.org
172.2${campus}.10.4		edge2-b1.campus${campus}.ws.nsrc.org
2001:DB8:${campus}:10::4	edge2-b1.campus${campus}.ws.nsrc.org
172.2${campus}.11.1		vlan11.core1.campus${campus}.ws.nsrc.org
2001:DB8:${campus}:11::1	vlan11.core1.campus${campus}.ws.nsrc.org
172.2${campus}.12.1		vlan12.core1.campus${campus}.ws.nsrc.org
2001:DB8:${campus}:12::1	vlan12.core1.campus${campus}.ws.nsrc.org
172.2${campus}.20.1		vlan20.core1.campus${campus}.ws.nsrc.org
2001:DB8:${campus}:20::1	vlan20.core1.campus${campus}.ws.nsrc.org
172.2${campus}.20.2		dist1-b2.campus${campus}.ws.nsrc.org
2001:DB8:${campus}:20::2	dist1-b2.campus${campus}.ws.nsrc.org
172.2${campus}.20.3		edge1-b2.campus${campus}.ws.nsrc.org
2001:DB8:${campus}:20::3	edge1-b2.campus${campus}.ws.nsrc.org
172.2${campus}.20.4		edge2-b2.campus${campus}.ws.nsrc.org
2001:DB8:${campus}:20::4	edge2-b2.campus${campus}.ws.nsrc.org
172.2${campus}.21.1		vlan21.core1.campus${campus}.ws.nsrc.org
2001:DB8:${campus}:21::1	vlan21.core1.campus${campus}.ws.nsrc.org
172.2${campus}.22.1		vlan22.core1.campus${campus}.ws.nsrc.org
2001:DB8:${campus}:22::1	vlan22.core1.campus${campus}.ws.nsrc.org
EOS
done
