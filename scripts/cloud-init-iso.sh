#!/bin/bash -eu

# Create the local data source ISOs for cloud-init to boot inside the GNS3 environment

# Inspired by https://github.com/asenci/gns3-ubuntu-cloud-init-data/
# See also:
# https://cloudinit.readthedocs.io/en/latest/topics/datasources/nocloud.html
# https://cloudinit.readthedocs.io/en/latest/topics/network-config-format-v1.html
# https://cloudinit.readthedocs.io/en/latest/topics/network-config-format-v2.html
# https://cloudinit.readthedocs.io/en/latest/topics/modules.html

ETH0='ens3'
ETH1='ens4'
PASSWD='$6$XqBb4pf3$rTN75u32r30VDbY252DwLLJ0rAuxIMvZceX02YFXK/WjAJ0FVjrUCQSkdPWA7nW0DoSNJrdu9w.PGOLbZmWlb/'
: "${TMPDIR:=/tmp}"
DATETIME="$(date -u +%Y%m%d%H%M)"

for i in $(seq 1 6); do
  FQDN="srv1.campus$i.ws.nsrc.org"
  IPV4="100.68.$i.130"
  IPV6="2001:db8:$i:1::130"
  BACKDOOR="192.168.122.$((i+220))"
  cat <<EOS >"$TMPDIR/user-data"
#cloud-config
fqdn: $FQDN
chpasswd: { expire: False }
ssh_pwauth: True
users:
  - name: sysadm
    gecos: Student System Administrator
    groups: [adm, audio, cdrom, dialout, dip, floppy, lpadmin, lxd, netdev, plugdev, sudo, video]
    lock_passwd: false
    passwd: $PASSWD
write_files:
  - path: /etc/hosts
    content: |
      $IPV4 $FQDN srv1
      $IPV6 $FQDN srv1
      127.0.0.1 localhost

      # The following lines are desirable for IPv6 capable hosts
      ::1 ip6-localhost ip6-loopback
      fe00::0 ip6-localnet
      ff00::0 ip6-mcastprefix
      ff02::1 ip6-allnodes
      ff02::2 ip6-allrouters
      ff02::3 ip6-allhosts
  # Assume classroom server has virbr0 on standard address and apt-cacher-ng is available
  - path: /etc/apt/apt.conf.d/99proxy
    content: |
      Acquire::http::Proxy "http://192.168.122.1:3142/";
  # Prefer IPv4 over IPv6 except when accessing 2001:db8:: addresses
  - path: /etc/gai.conf
    content: |
      # New label table with separate label for 2001:db8::/32.
      # The RFC 3484 rules prefer the source and destination to have
      # the same label. So if we have a 2001:db8 source address and are
      # connecting to something on the public Internet which has both
      # v4 and v6 addresses, we will prefer to use v4 (where the source
      # and destination both have label "4") rather than v6.
      label ::1/128       0
      label ::/0          1
      label 2002::/16     2
      label ::/96         3
      label ::ffff:0:0/96 4
      label fec0::/10     5
      label fc00::/7      6
      label 2001:0::/32   7
      label 2001:db8::/32 8
  - path: /etc/sysctl.d/00-ipv6-sanity.conf
    content: |
      # Disable assignment of SLAAC addresses
      net.ipv6.conf.all.autoconf = 0
      net.ipv6.conf.default.autoconf = 0
      net.ipv6.conf.$ETH0.autoconf = 0
      net.ipv6.conf.$ETH1.autoconf = 0
      net.ipv6.conf.all.accept_ra_pinfo = 0
      net.ipv6.conf.default.accept_ra_pinfo = 0
      net.ipv6.conf.$ETH0.accept_ra_pinfo = 0
      net.ipv6.conf.$ETH1.accept_ra_pinfo = 0

      # Disable picking up defrtr and other parameters via RAs
      net.ipv6.conf.all.accept_ra = 0
      net.ipv6.conf.default.accept_ra = 0
      net.ipv6.conf.$ETH0.accept_ra = 0
      net.ipv6.conf.$ETH1.accept_ra = 0
      net.ipv6.conf.all.accept_ra_defrtr = 0
      net.ipv6.conf.default.accept_ra_defrtr = 0
      net.ipv6.conf.$ETH0.accept_ra_defrtr = 0
      net.ipv6.conf.$ETH1.accept_ra_defrtr = 0
      net.ipv6.conf.all.router_solicitations = 0
      net.ipv6.conf.default.router_solicitations = 0
      net.ipv6.conf.$ETH0.router_solicitations = 0
      net.ipv6.conf.$ETH1.router_solicitations = 0

      # Disable use of privacy address (should only affect SLAAC but just in case)
      net.ipv6.conf.all.use_tempaddr = 0
      net.ipv6.conf.default.use_tempaddr = 0
      net.ipv6.conf.$ETH0.use_tempaddr = 0
      net.ipv6.conf.$ETH1.use_tempaddr = 0

      # Disable duplicate address detection
      net.ipv6.conf.all.accept_dad = 0
      net.ipv6.conf.default.accept_dad = 0
      net.ipv6.conf.$ETH0.accept_dad = 0
      net.ipv6.conf.$ETH1.accept_dad = 0
      net.ipv6.conf.all.dad_transmits = 0
      net.ipv6.conf.default.dad_transmits = 0
      net.ipv6.conf.$ETH0.dad_transmits = 0
      net.ipv6.conf.$ETH1.dad_transmits = 0
EOS
  # version 2 appears to be broken on Ubuntu 16.04: it doesn't add
  # dns-nameservers or dns-search to /etc/network/interfaces.d/50-cloud-init.cfg
  cat <<EOS >"$TMPDIR/network-config"
version: 1
config:
  - type: physical
    name: $ETH0
    subnets:
      - type: static
        address: $IPV4/28
        gateway: 100.68.$i.129
      - type: static
        address: $IPV6/64
        gateway: 2001:db8:$i:1::1
  - type: physical
    name: $ETH1
    subnets:
      - type: static
        address: $BACKDOOR/24
  - type: nameserver
    address:
      - 192.168.122.1
    search:
      - campus$i.ws.nsrc.org
      - ws.nsrc.org
EOS
  yamllint "$TMPDIR/user-data"
  yamllint "$TMPDIR/network-config"
  cloud-localds -H "$FQDN" -N "$TMPDIR/network-config" \
      "iso/srv1-campus${i}-init-$DATETIME.iso" "$TMPDIR/user-data"
done
