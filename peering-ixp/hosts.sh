#!/bin/bash -eu

cat <<EOS
# Use this file to replace your /etc/hosts, or append it to the end

127.0.0.1	localhost
::1     localhost ip6-localhost ip6-loopback
ff02::1 ip6-allnodes
ff02::2 ip6-allrouters

### Management ###

192.168.122.1		vtp.ws.nsrc.org apt.ws.nsrc.org gns3.ws.nsrc.org www.ws.nsrc.org gw.ws.nsrc.org
192.168.122.249		elk.ws.nsrc.org kibana.ws.nsrc.org elk
2001:DB8:0:0::249	elk.ws.nsrc.org kibana.ws.nsrc.org elk
192.168.122.250		noc.ws.nsrc.org noc
2001:DB8::250		noc.ws.nsrc.org noc
192.168.122.251		ap1.ws.nsrc.org ap1
192.168.122.252		ap2.ws.nsrc.org ap2
192.168.122.253		sw.ws.nsrc.org sw
192.168.122.254		tr-vrrp.ws.nsrc.org tr-vrrp

### Core infrastructure ###
EOS

for TR in $(seq 1 2); do
  cat <<EOS

192.168.122.$(( TR+1 ))	gi0-0.tr${TR}.ws.nsrc.org tr${TR}.ws.nsrc.org tr${TR}
2001:DB8::$(( TR+1 ))	gi0-0.tr${TR}.ws.nsrc.org
2001:18::$(( TR-1 ))	gi0-0.tr${TR}.ws.nsrc.org
EOS
  for G in $(seq 1 9); do
    cat <<EOS
100.$(( TR+120 )).1.$(( (G-1)*2 ))	gi0-$G.tr${TR}.ws.nsrc.org
2001:$(( TR+17 )):0:$(( G+9 ))::	gi0-$G.tr${TR}.ws.nsrc.org
EOS
  done
done
cat <<EOS

100.127.0.10		ens3.rs1.ws.nsrc.org
2001:db8:ffff:2::10	ens3.rs1.ws.nsrc.org
100.127.1.254		ens4.rs1.ws.nsrc.org
2001:db8:ffff:1::fe	ens4.rs1.ws.nsrc.org
192.168.122.5		ens5.rs1.ws.nsrc.org rs1.ws.nsrc.org rs1

100.127.2.10		ens3.rs2.ws.nsrc.org
2001:db8:fffe:2::10	ens3.rs2.ws.nsrc.org
100.127.3.254		ens4.rs2.ws.nsrc.org
2001:db8:fffe:1::fe	ens4.rs2.ws.nsrc.org
192.168.122.6		ens5.rs2.ws.nsrc.org rs2.ws.nsrc.org rs2

100.121.1.17	gi0-0.sr1.ws.nsrc.org
2001:18:0:18::1	gi0-0.sr1.ws.nsrc.org
100.127.0.9	gi0-1.sr1.ws.nsrc.org
2001:DB8:FFFF:2::9	gi0-1.sr1.ws.nsrc.org
100.127.1.253	gi0-2.sr1.ws.nsrc.org
2001:DB8:FFFF:1::FD	gi0-2.sr1.ws.nsrc.org
100.127.0.1	gi0-3.sr1.ws.nsrc.org sr1.ws.nsrc.org sr1
2001:DB8:FFFF::1	gi0-3.sr1.ws.nsrc.org sr1.ws.nsrc.org sr1

100.122.1.17	gi0-0.sr2.ws.nsrc.org
2001:19:0:18::1	gi0-0.sr2.ws.nsrc.org
100.127.2.9	gi0-1.sr2.ws.nsrc.org
2001:DB8:FFFE:2::9	gi0-1.sr2.ws.nsrc.org
100.127.3.253	gi0-2.sr2.ws.nsrc.org
2001:DB8:FFFE:1::FD	gi0-2.sr2.ws.nsrc.org
100.127.2.1	gi0-3.sr2.ws.nsrc.org sr2.ws.nsrc.org sr2
2001:DB8:FFFE::1	gi0-3.sr2.ws.nsrc.org sr2.ws.nsrc.org sr2

100.127.0.2	ixp1.ws.nsrc.org ixp1
2001:DB8:FFFF::2	ixp1.ws.nsrc.org ixp1

100.127.2.2	ixp2.ws.nsrc.org ixp2
2001:DB8:FFFE::2	ixp2.ws.nsrc.org ixp2
EOS

for GROUP in $(seq 1 8); do
  OTHER="$(( ((GROUP-1)^1) + 1 ))"

  # Border calc
  TRANSIT1_AS="$(( (GROUP-1) / 4 + 121 ))"
  TRANSIT1_V6="$(( (GROUP-1) / 4 + 18 ))"
  TRANSIT1_LOCAL_V4="100.${TRANSIT1_AS}.1.$((GROUP*2-1))"
  TRANSIT1_LOCAL_V6="2001:${TRANSIT1_V6}:0:$((GROUP+9))::1"

  # Private peering calc
  LINK_GROUP="$(( ((GROUP - 1) & -2) + 1 ))"

  PEER_LO_V4="100.68.${LINK_GROUP}.32"
  PEER_HI_V4="100.68.${LINK_GROUP}.33"

  PEER_LO_V6="2001:DB8:${LINK_GROUP}:30::"
  PEER_HI_V6="2001:DB8:${LINK_GROUP}:30::1"

  if (( (GROUP & 1) == 1 )); then
    PEER_LOCAL_V4="$PEER_LO_V4"
    PEER_LOCAL_V6="$PEER_LO_V6"
  else
    PEER_LOCAL_V4="$PEER_HI_V4"
    PEER_LOCAL_V6="$PEER_HI_V6"
  fi
  cat <<EOS

### Group ${GROUP} ###

100.68.${GROUP}.1	lo0.b${GROUP}.ws.nsrc.org b${GROUP}.ws.nsrc.org b${GROUP}
2001:DB8:${GROUP}::1	lo0.b${GROUP}.ws.nsrc.org b${GROUP}.ws.nsrc.org b${GROUP}
100.68.${GROUP}.17	gi0-1.b${GROUP}.ws.nsrc.org
2001:DB8:${GROUP}:10::1	gi0-1.b${GROUP}.ws.nsrc.org
${TRANSIT1_LOCAL_V4}	gi0-2.b${GROUP}.ws.nsrc.org
${TRANSIT1_LOCAL_V6}	gi0-2.b${GROUP}.ws.nsrc.org

100.68.${GROUP}.2	lo0.c${GROUP}.ws.nsrc.org c${GROUP}.ws.nsrc.org c${GROUP}
2001:DB8:${GROUP}::2	lo0.c${GROUP}.ws.nsrc.org c${GROUP}.ws.nsrc.org c${GROUP}
100.68.${GROUP}.16	gi0-1.c${GROUP}.ws.nsrc.org
2001:DB8:${GROUP}:10::	gi0-1.c${GROUP}.ws.nsrc.org
100.68.${GROUP}.18	gi0-2.c${GROUP}.ws.nsrc.org
2001:DB8:${GROUP}:11::	gi0-2.c${GROUP}.ws.nsrc.org
100.68.${GROUP}.20	gi0-3.c${GROUP}.ws.nsrc.org
2001:DB8:${GROUP}:12::	gi0-3.c${GROUP}.ws.nsrc.org
100.68.${GROUP}.29	gi0-4.c${GROUP}.ws.nsrc.org
2001:DB8:${GROUP}:21::29	gi0-4.c${GROUP}.ws.nsrc.org

100.68.${GROUP}.3	lo0.p${GROUP}.ws.nsrc.org p${GROUP}.ws.nsrc.org p${GROUP}
2001:DB8:${GROUP}::3	lo0.p${GROUP}.ws.nsrc.org p${GROUP}.ws.nsrc.org p${GROUP}
100.68.${GROUP}.19	gi0-1.p${GROUP}.ws.nsrc.org
2001:DB8:${GROUP}:11::1	gi0-1.p${GROUP}.ws.nsrc.org
${PEER_LOCAL_V4}	gi0-2.p${GROUP}.ws.nsrc.org
${PEER_LOCAL_V6}	gi0-2.p${GROUP}.ws.nsrc.org
100.127.1.${GROUP}	gi0-3.p${GROUP}.ws.nsrc.org
2001:DB8:FFFF:1::${GROUP}	gi0-3.p${GROUP}.ws.nsrc.org
100.127.3.${GROUP}	gi0-4.p${GROUP}.ws.nsrc.org
2001:DB8:FFFE:1::${GROUP}	gi0-4.p${GROUP}.ws.nsrc.org

100.68.${GROUP}.4	lo0.a${GROUP}.ws.nsrc.org a${GROUP}.ws.nsrc.org a${GROUP}
2001:DB8:${GROUP}::4	lo0.a${GROUP}.ws.nsrc.org a${GROUP}.ws.nsrc.org a${GROUP}
100.68.${GROUP}.21	gi0-1.a${GROUP}.ws.nsrc.org
2001:DB8:${GROUP}:12::1	gi0-1.a${GROUP}.ws.nsrc.org
100.68.${GROUP}.34	gi0-2.a${GROUP}.ws.nsrc.org
2001:DB8:${GROUP}:31::	gi0-2.a${GROUP}.ws.nsrc.org
100.68.${GROUP}.36	gi0-3.a${GROUP}.ws.nsrc.org
2001:DB8:${GROUP}:32::	gi0-3.a${GROUP}.ws.nsrc.org

100.68.${GROUP}.64	lo0.cust${GROUP}.ws.nsrc.org cust${GROUP}.ws.nsrc.org cust${GROUP}
2001:DB8:${GROUP}:4000::	lo0.cust${GROUP}.ws.nsrc.org cust${GROUP}.ws.nsrc.org cust${GROUP}
100.68.$(( GROUP+100 )).1	lo1.cust${GROUP}.ws.nsrc.org
2001:DB8:$(( GROUP+100 ))::1	lo1.cust${GROUP}.ws.nsrc.org
100.68.${GROUP}.35	gi0-1.cust${GROUP}.ws.nsrc.org
2001:DB8:${GROUP}:31::1	gi0-1.cust${GROUP}.ws.nsrc.org
100.68.${OTHER}.37	gi0-2.cust${GROUP}.ws.nsrc.org
2001:DB8:${OTHER}:32::1	gi0-2.cust${GROUP}.ws.nsrc.org

100.68.${GROUP}.30	ens3.srv${GROUP}.ws.nsrc.org
2001:db8:${GROUP}:21::30	ens3.srv${GROUP}.ws.nsrc.org
192.168.122.$(( GROUP*10 ))	ens4.srv${GROUP}.ws.nsrc.org srv${GROUP}.ws.nsrc.org srv${GROUP}
EOS
done
