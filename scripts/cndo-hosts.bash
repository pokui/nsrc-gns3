#!/bin/bash -eu

cat <<EOS
# Devices on backbone
192.168.122.1		vtp.ws.nsrc.org apt.ws.nsrc.org
192.168.122.201		gi0-0.transit1.nren.ws.nsrc.org transit1.nren.ws.nsrc.org
2001:DB8:100::235	gi0-0.transit1.nren.ws.nsrc.org transit1.nren.ws.nsrc.org
192.168.122.202		gi0-0.transit2.nren.ws.nsrc.org transit2.nren.ws.nsrc.org
2001:DB8:100::236	gi0-0.transit2.nren.ws.nsrc.org transit2.nren.ws.nsrc.org
EOS

for campus in $(seq 1 6); do
cat <<EOS
192.168.122.$((220+campus))		srv1-ens4.campus${campus}.ws.nsrc.org srv1.campus${campus}.ws.nsrc.org librenms.campus${campus}.ws.nsrc.org rt.campus${campus}.ws.nsrc.org nfsen.campus${campus}.ws.nsrc.org srv1-campus${campus}
EOS
done

cat <<EOS
192.168.122.250		unifi.ws.nsrc.org
192.168.122.251		ap1.ws.nsrc.org
192.168.122.252		ap2.ws.nsrc.org
192.168.122.253		sw.ws.nsrc.org

# Transit links
100.68.0.1		gi0-1.transit1.nren.ws.nsrc.org
2001:DB8:100:1::	gi0-1.transit1.nren.ws.nsrc.org
100.68.0.5		gi0-2.transit1.nren.ws.nsrc.org
2001:DB8:100:2::	gi0-2.transit1.nren.ws.nsrc.org
100.68.0.9		gi0-3.transit1.nren.ws.nsrc.org
2001:DB8:100:3::	gi0-3.transit1.nren.ws.nsrc.org
100.68.0.13		gi0-4.transit1.nren.ws.nsrc.org
2001:DB8:100:4::	gi0-4.transit1.nren.ws.nsrc.org
100.68.0.17		gi0-5.transit1.nren.ws.nsrc.org
2001:DB8:100:5::	gi0-5.transit1.nren.ws.nsrc.org
100.68.0.21		gi0-6.transit1.nren.ws.nsrc.org
2001:DB8:100:6::	gi0-6.transit1.nren.ws.nsrc.org
100.68.0.251		lo0.transit1.nren.ws.nsrc.org
2001:DB8:100:FF::251	lo0.transit1.nren.ws.nsrc.org
100.68.0.252		lo0.transit2.nren.ws.nsrc.org
2001:DB8:100:FF::252	lo0.transit2.nren.ws.nsrc.org
EOS

for campus in $(seq 1 6); do
cat <<EOS

# Campus ${campus}
100.68.${campus}.130		srv1-ens3.campus${campus}.ws.nsrc.org
2001:DB8:${campus}:1::130	srv1-ens3.campus${campus}.ws.nsrc.org
EOS
for i in $(seq 1 6); do
cat <<EOS
100.68.${campus}.$((130+i))		host${i}.campus${campus}.ws.nsrc.org host${i}-campus${campus}
2001:DB8:${campus}:1::$((130+i))	host${i}.campus${campus}.ws.nsrc.org host${i}-campus${campus}
EOS
done
cat <<EOS

100.68.${campus}.1		gi0-1.bdr1.campus${campus}.ws.nsrc.org bdr1.campus${campus}.ws.nsrc.org
2001:DB8:${campus}:0::1		gi0-1.bdr1.campus${campus}.ws.nsrc.org bdr1.campus${campus}.ws.nsrc.org
100.68.0.$((campus*4+2))		gi0-0.bdr1.campus${campus}.ws.nsrc.org
2001:DB8:100:${campus}::1	gi0-0.bdr1.campus${campus}.ws.nsrc.org
100.68.${campus}.241		lo0.bdr1.campus${campus}.ws.nsrc.org
2001:DB8:${campus}:2::241	lo0.bdr1.campus${campus}.ws.nsrc.org

100.68.${campus}.2		fi0-0.core1.campus${campus}.ws.nsrc.org core1.campus${campus}.ws.nsrc.org
2001:DB8:${campus}:0::2		fi0-0.core1.campus${campus}.ws.nsrc.org core1.campus${campus}.ws.nsrc.org
100.68.${campus}.129		gi0-3.core1.campus${campus}.ws.nsrc.org
2001:DB8:${campus}:1::1		gi0-3.core1.campus${campus}.ws.nsrc.org
100.68.${campus}.242		lo0.core1.campus${campus}.ws.nsrc.org
2001:DB8:${campus}:2::242	lo0.core1.campus${campus}.ws.nsrc.org

172.2${campus}.10.1		vlan10.core1.campus${campus}.ws.nsrc.org
2001:DB8:${campus}:10::1	vlan10.core1.campus${campus}.ws.nsrc.org
172.2${campus}.11.1		vlan11.core1.campus${campus}.ws.nsrc.org
2001:DB8:${campus}:11::1	vlan11.core1.campus${campus}.ws.nsrc.org
172.2${campus}.12.1		vlan12.core1.campus${campus}.ws.nsrc.org
2001:DB8:${campus}:12::1	vlan12.core1.campus${campus}.ws.nsrc.org
172.2${campus}.10.2		dist1-b1.campus${campus}.ws.nsrc.org
2001:DB8:${campus}:10::2	dist1-b1.campus${campus}.ws.nsrc.org
172.2${campus}.10.3		edge1-b1.campus${campus}.ws.nsrc.org
2001:DB8:${campus}:10::3	edge1-b1.campus${campus}.ws.nsrc.org
172.2${campus}.10.4		edge2-b1.campus${campus}.ws.nsrc.org
2001:DB8:${campus}:10::4	edge2-b1.campus${campus}.ws.nsrc.org
172.2${campus}.20.1		vlan20.core1.campus${campus}.ws.nsrc.org
2001:DB8:${campus}:20::1	vlan20.core1.campus${campus}.ws.nsrc.org
172.2${campus}.21.1		vlan21.core1.campus${campus}.ws.nsrc.org
2001:DB8:${campus}:21::1	vlan21.core1.campus${campus}.ws.nsrc.org
172.2${campus}.22.1		vlan22.core1.campus${campus}.ws.nsrc.org
2001:DB8:${campus}:22::1	vlan22.core1.campus${campus}.ws.nsrc.org
172.2${campus}.20.2		dist1-b2.campus${campus}.ws.nsrc.org
2001:DB8:${campus}:20::2	dist1-b2.campus${campus}.ws.nsrc.org
172.2${campus}.20.3		edge1-b2.campus${campus}.ws.nsrc.org
2001:DB8:${campus}:20::3	edge1-b2.campus${campus}.ws.nsrc.org
172.2${campus}.20.4		edge2-b2.campus${campus}.ws.nsrc.org
2001:DB8:${campus}:20::4	edge2-b2.campus${campus}.ws.nsrc.org
EOS
done
