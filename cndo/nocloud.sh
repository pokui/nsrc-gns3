#!/bin/bash -eu

# Create the local data source for cloud-init to boot inside the GNS3 environment

# Inspired by https://github.com/asenci/gns3-ubuntu-cloud-init-data/
# See also:
# https://cloudinit.readthedocs.io/en/latest/topics/datasources/nocloud.html
# https://cloudinit.readthedocs.io/en/latest/topics/network-config-format-v1.html
# https://cloudinit.readthedocs.io/en/latest/topics/network-config-format-v2.html
# https://cloudinit.readthedocs.io/en/latest/topics/modules.html

# The "accept-ra" extension is important because we must not pick up
# RA's from classroom backbone (virbr0) if they are in use.  It's undocumented:
# https://git.launchpad.net/cloud-init/commit/?id=62bbc262c3c7f633eac1d09ec78c055eef05166a

# NOTE: after modifying config, you can reinitialize an existing VM using
#   sudo cloud-init clean     # (this also wipes ssh keys etc)
#   sudo cloud-init init

# Sadly, the network-config file does not support '## template:jinja' and therefore
# we have to make separate cloud-init configs for each campus

ETH0='ens3'
ETH1='ens4'
PASSWD='$6$XqBb4pf3$rTN75u32r30VDbY252DwLLJ0rAuxIMvZceX02YFXK/WjAJ0FVjrUCQSkdPWA7nW0DoSNJrdu9w.PGOLbZmWlb/'
: "${TMPDIR:=/tmp}"
DATE="$(date -u +%Y%m%d)"

mkdir -p nocloud
for i in $(seq 1 6); do
  FQDN="srv1.campus$i.ws.nsrc.org"
  IPV4="100.68.$i.130"
  IPV6="2001:db8:$i:1::130"
  BACKDOOR="100.64.0.$((10*i))"

  ######## NETWORK CONFIG ########
  # Note: stock ubuntu-cloud image does not have bridge-utils
  cat <<EOS >"$TMPDIR/network-config"
version: 2
ethernets:
  $ETH0:
    accept-ra: false
    addresses:
      - $IPV4/28
      - $IPV6/64
    gateway4: 100.68.$i.129
    gateway6: 2001:db8:$i:1::1
  $ETH1:
    accept-ra: false
    addresses:
      - $BACKDOOR/22
    nameservers:
      addresses:
        - 100.64.0.1
      search:
        - campus$i.ws.nsrc.org
        - ws.nsrc.org
EOS

  ######## USER DATA ########
  # This configures all other aspects of boot, including creating user/password.
  cat <<EOS >"$TMPDIR/user-data"
#cloud-config
fqdn: $FQDN
chpasswd: { expire: False }
ssh_pwauth: True
users:
  - name: sysadm
    gecos: Student System Administrator
    groups: [adm, audio, cdrom, dialout, dip, floppy, lxd, netdev, plugdev, sudo, video]
    lock_passwd: false
    passwd: $PASSWD
    shell: /bin/bash
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
  # Policy routing so inbound traffic to 100.64.0.0/22 always returns via same interface
  - path: /etc/iproute2/rt_tables
    append: true
    content: |
      150	backdoor
  - path: /etc/networkd-dispatcher/routable.d/50-backdoor
    permissions: '0755'
    content: |
      #!/bin/bash
      if [ "\$IFACE" = "$ETH1" ]; then
        # Apply policy routing
        ip rule add from $BACKDOOR table backdoor
        ip route add default via 100.64.0.1 dev $ETH1 metric 100 table backdoor
        ip route add 100.64.0.0/22 dev $ETH1  proto kernel  scope link  src $BACKDOOR  table backdoor
        ip route flush cache
      fi
  - path: /etc/sysctl.d/90-rpf.conf
    content: |
      # Loose reverse path filtering (traffic from 100.64.0.0/22 address may come in via $ETH0)
      net.ipv4.conf.all.rp_filter=2
runcmd:
  # YAML doesn't need escaping of backslash, but shell (cat <<END2) does
  - sed -i -r -e 's#(\\\\h)([^.])#\\1.campus$i\\2#g' /etc/profile /etc/bash.bashrc /etc/skel/.bashrc /root/.bashrc /home/*/.bashrc
  - IFACE=$ETH1 /etc/networkd-dispatcher/routable.d/50-backdoor
  - sysctl -p /etc/sysctl.d/90-rpf.conf
final_message: NSRC welcomes you to CNDO!
EOS
  yamllint -d relaxed "$TMPDIR/user-data"
  yamllint -d relaxed "$TMPDIR/network-config"
  OUTFILE="nocloud/cndo-srv1-campus${i}-hdb.img"
  rm -f "$OUTFILE"
  cloud-localds -f vfat -d raw -H "$FQDN" -N "$TMPDIR/network-config" \
      "$OUTFILE" "$TMPDIR/user-data"
  md5sum -b "$OUTFILE" | head -c32 >"$OUTFILE.md5sum"
  ln "$OUTFILE" "nocloud/cndo-srv1-campus${i}-hdb-${DATE}-$(head -c8 "$OUTFILE.md5sum").img"
  ln "$OUTFILE.md5sum" "nocloud/cndo-srv1-campus${i}-hdb-${DATE}-$(head -c8 "$OUTFILE.md5sum").img.md5sum"
  rm "$OUTFILE" "$OUTFILE.md5sum"
done
