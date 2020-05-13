#!/bin/bash -eu

cat <<EOS
# Use this file to replace your /etc/hosts, or append it to the end

127.0.0.1	localhost
::1     localhost ip6-localhost ip6-loopback
ff02::1 ip6-allnodes
ff02::2 ip6-allrouters

### Management ###

192.168.122.1		vtp.ws.nsrc.org apt.ws.nsrc.org rpki.ws.nsrc.org gns3.ws.nsrc.org www.ws.nsrc.org gw.ws.nsrc.org vtp
192.168.122.8		vtp2.ws.nsrc.org vtp2
192.168.122.250		noc.ws.nsrc.org librenms.ws.nsrc.org rt.ws.nsrc.org nfsen.ws.nsrc.org noc
2001:DB8::250		noc.ws.nsrc.org librenms.ws.nsrc.org rt.ws.nsrc.org nfsen.ws.nsrc.org noc
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
  for G in $(seq 1 5); do
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

100.121.1.9	gi0-0.sr1.ws.nsrc.org
2001:18:0:14::1	gi0-0.sr1.ws.nsrc.org
100.127.0.9	gi0-1.sr1.ws.nsrc.org
2001:DB8:FFFF:2::9	gi0-1.sr1.ws.nsrc.org
100.127.1.253	gi0-2.sr1.ws.nsrc.org
2001:DB8:FFFF:1::FD	gi0-2.sr1.ws.nsrc.org
100.127.0.1	gi0-3.sr1.ws.nsrc.org sr1.ws.nsrc.org sr1
2001:DB8:FFFF::1	gi0-3.sr1.ws.nsrc.org sr1.ws.nsrc.org sr1

100.122.1.9	gi0-0.sr2.ws.nsrc.org
2001:19:0:14::1	gi0-0.sr2.ws.nsrc.org
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

for GHI in $(seq 0 1); do
for GLO in $(seq 0 3); do
  GROUP=$(( GHI*4 + GLO + 1 ))

  # Border calc
  TRANSIT_AS="$(( GHI + 121 ))"
  TRANSIT_V6="$(( GHI + 18 ))"
  TRANSIT_LOCAL_V4="100.${TRANSIT_AS}.1.$((GLO*2+1))"
  TRANSIT_LOCAL_V6="2001:${TRANSIT_V6}:0:$((GLO+10))::1"

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
  IXP_V4="100.127.$((GHI*2+1)).$((GLO+1))"
  IXP_V6="2001:DB8:$( printf "%04X" $(( 65535 - GHI)) ):1::$((GLO+1))"
  cat <<EOS

### Group ${GROUP} ###

100.68.${GROUP}.1	lo0.b${GROUP}.ws.nsrc.org b${GROUP}.ws.nsrc.org b${GROUP}
2001:DB8:${GROUP}::1	lo0.b${GROUP}.ws.nsrc.org b${GROUP}.ws.nsrc.org b${GROUP}
100.68.${GROUP}.17	gi1.b${GROUP}.ws.nsrc.org
2001:DB8:${GROUP}:10::1	gi1.b${GROUP}.ws.nsrc.org
${TRANSIT_LOCAL_V4}	gi2.b${GROUP}.ws.nsrc.org
${TRANSIT_LOCAL_V6}	gi2.b${GROUP}.ws.nsrc.org

100.68.${GROUP}.2	lo0.c${GROUP}.ws.nsrc.org c${GROUP}.ws.nsrc.org c${GROUP}
2001:DB8:${GROUP}::2	lo0.c${GROUP}.ws.nsrc.org c${GROUP}.ws.nsrc.org c${GROUP}
100.68.${GROUP}.16	gi1.c${GROUP}.ws.nsrc.org
2001:DB8:${GROUP}:10::	gi1.c${GROUP}.ws.nsrc.org
100.68.${GROUP}.18	gi2.c${GROUP}.ws.nsrc.org
2001:DB8:${GROUP}:11::	gi2.c${GROUP}.ws.nsrc.org
100.68.${GROUP}.20	gi3.c${GROUP}.ws.nsrc.org
2001:DB8:${GROUP}:12::	gi3.c${GROUP}.ws.nsrc.org
100.68.${GROUP}.29	gi4.c${GROUP}.ws.nsrc.org
2001:DB8:${GROUP}:21::29	gi4.c${GROUP}.ws.nsrc.org
100.68.${GROUP}.22	gi5.c${GROUP}.ws.nsrc.org
2001:DB8:${GROUP}:13::	gi5.c${GROUP}.ws.nsrc.org

100.68.${GROUP}.3	lo0.p${GROUP}.ws.nsrc.org p${GROUP}.ws.nsrc.org p${GROUP}
2001:DB8:${GROUP}::3	lo0.p${GROUP}.ws.nsrc.org p${GROUP}.ws.nsrc.org p${GROUP}
100.68.${GROUP}.19	gi1.p${GROUP}.ws.nsrc.org
2001:DB8:${GROUP}:11::1	gi1.p${GROUP}.ws.nsrc.org
${PEER_LOCAL_V4}	gi2.p${GROUP}.ws.nsrc.org
${PEER_LOCAL_V6}	gi2.p${GROUP}.ws.nsrc.org
${IXP_V4}	gi3.p${GROUP}.ws.nsrc.org
${IXP_V6}	gi3.p${GROUP}.ws.nsrc.org

100.68.${GROUP}.4	lo0.a${GROUP}.ws.nsrc.org a${GROUP}.ws.nsrc.org a${GROUP}
2001:DB8:${GROUP}::4	lo0.a${GROUP}.ws.nsrc.org a${GROUP}.ws.nsrc.org a${GROUP}
100.68.${GROUP}.21	gi1.a${GROUP}.ws.nsrc.org
2001:DB8:${GROUP}:12::1	gi1.a${GROUP}.ws.nsrc.org
100.68.${GROUP}.34	gi2.a${GROUP}.ws.nsrc.org
2001:DB8:${GROUP}:31::	gi2.a${GROUP}.ws.nsrc.org

100.68.${GROUP}.64	lo0.cust${GROUP}.ws.nsrc.org cust${GROUP}.ws.nsrc.org cust${GROUP}
2001:DB8:${GROUP}:4000::	lo0.cust${GROUP}.ws.nsrc.org cust${GROUP}.ws.nsrc.org cust${GROUP}
100.68.$(( GROUP+100 )).1	lo1.cust${GROUP}.ws.nsrc.org
2001:DB8:$(( GROUP+100 ))::1	lo1.cust${GROUP}.ws.nsrc.org
100.68.${GROUP}.35	gi0-1.cust${GROUP}.ws.nsrc.org
2001:DB8:${GROUP}:31::1	gi0-1.cust${GROUP}.ws.nsrc.org

100.68.${GROUP}.5	lo0.t${GROUP}.ws.nsrc.org t${GROUP}.ws.nsrc.org t${GROUP}
2001:DB8:${GROUP}::5	lo0.t${GROUP}.ws.nsrc.org t${GROUP}.ws.nsrc.org t${GROUP}
100.68.${GROUP}.23	gi0-1.t${GROUP}.ws.nsrc.org
2001:DB8:${GROUP}:13::1	gi0-1.t${GROUP}.ws.nsrc.org

100.68.${GROUP}.30	ens3.srv${GROUP}.ws.nsrc.org
2001:db8:${GROUP}:21::30	ens3.srv${GROUP}.ws.nsrc.org
192.168.122.$(( GROUP*10 ))	ens4.srv${GROUP}.ws.nsrc.org srv${GROUP}.ws.nsrc.org srv${GROUP}
EOS
done
done
