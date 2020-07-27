#!/bin/bash -eu

# Create the local data source for cloud-init to boot inside the GNS3 environment

# Inspired by https://github.com/asenci/gns3-ubuntu-cloud-init-data/
# See also:
# https://cloudinit.readthedocs.io/en/latest/topics/datasources/nocloud.html
# https://cloudinit.readthedocs.io/en/latest/topics/network-config-format-v1.html
# https://cloudinit.readthedocs.io/en/latest/topics/network-config-format-v2.html
# https://cloudinit.readthedocs.io/en/latest/topics/modules.html

# NOTE: after modifying config, you can reinitialize an existing VM using
#   sudo cloud-init clean     # (this also wipes ssh keys etc)
#   sudo cloud-init init

ETH0='ens3'
PASSWD='$6$XqBb4pf3$rTN75u32r30VDbY252DwLLJ0rAuxIMvZceX02YFXK/WjAJ0FVjrUCQSkdPWA7nW0DoSNJrdu9w.PGOLbZmWlb/'
: "${TMPDIR:=/tmp}"
DATE="$(date -u +%Y%m%d)"

mkdir -p nocloud

FQDN="elk.ws.nsrc.org"
IPV4="100.64.0.249"
IPV6="2001:db8:0:0::249"

######## NETWORK CONFIG ########
cat <<EOS >"$TMPDIR/network-config"
version: 2
ethernets:
  $ETH0:
    accept-ra: false
    addresses:
      - $IPV4/22
      - $IPV6/64
    gateway4: 100.64.0.1
    gateway6: 2001:db8:0:0::254
    nameservers:
      addresses:
        - 100.64.0.1
      search:
        - ws.nsrc.org
EOS

######## USER DATA ########
# This configures all other aspects of boot, including creating user/password.
# runcmd clones the hostN containers and configures *their* networking and user too.
cat <<EOS >"$TMPDIR/user-data"
#cloud-config
fqdn: $FQDN
chpasswd: { expire: False }
ssh_pwauth: True
users:
  - name: sysadm
    gecos: System Administrator
    groups: [adm, audio, cdrom, dialout, dip, floppy, lxd, netdev, plugdev, sudo, video]
    lock_passwd: false
    passwd: $PASSWD
    shell: /bin/bash
write_files:
  - path: /etc/hosts
    content: |
      $IPV4 $FQDN elk
      $IPV6 $FQDN elk
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
      Acquire::http::Proxy "http://100.64.0.1:3142/";
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
      label 2001:db8::/32 6
      label 2001:10::/28  6
runcmd:
  # Fixup https repositories to use proxy
  - sed -i -e 's#https://#http://HTTPS///#' /etc/apt/sources.list /etc/apt/sources.list.d/*.list
final_message: ELK is ready!
EOS

yamllint -d relaxed "$TMPDIR/user-data"
yamllint -d relaxed "$TMPDIR/network-config"
OUTFILE="nocloud/elk-hdb.img"
rm -f "$OUTFILE"
cloud-localds -f vfat -d raw -H "$FQDN" -N "$TMPDIR/network-config" \
    "$OUTFILE" "$TMPDIR/user-data"
md5sum -b "$OUTFILE" | head -c32 >"$OUTFILE.md5sum"
ln "$OUTFILE" "nocloud/elk-hdb-${DATE}-$(head -c8 "$OUTFILE.md5sum").img"
ln "$OUTFILE.md5sum" "nocloud/elk-hdb-${DATE}-$(head -c8 "$OUTFILE.md5sum").img.md5sum"
rm "$OUTFILE" "$OUTFILE.md5sum"
