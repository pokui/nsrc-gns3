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

# Sadly, the network-config file does not support '## template:jinja' and therefore
# we have to make separate cloud-init configs for each campus

ETH0='ens3'
PASSWD='$6$XqBb4pf3$rTN75u32r30VDbY252DwLLJ0rAuxIMvZceX02YFXK/WjAJ0FVjrUCQSkdPWA7nW0DoSNJrdu9w.PGOLbZmWlb/'
: "${TMPDIR:=/tmp}"
DATE="$(date -u +%Y%m%d)"

mkdir -p nocloud

FQDN="noc.ws.nsrc.org"
IPV4="192.168.122.250"
IPV6="2001:db8:0:0::250"

######## NETWORK CONFIG ########
# Note: version 2 appears to be broken on Ubuntu 16.04: it doesn't add
# dns-nameservers or dns-search to /etc/network/interfaces.d/50-cloud-init.cfg
cat <<EOS >"$TMPDIR/network-config"
version: 1
config:
  - type: physical
    name: $ETH0
  - type: bridge
    name: br0
    bridge_interfaces:
      - $ETH0
    params:
      bridge_fd: 0
      bridge_maxwait: 0
      bridge_stp: 'off'
    subnets:
      - type: static
        address: $IPV4/28
        gateway: 192.168.122.1
      - type: static
        address: $IPV6/64
        gateway: 2001:db8:0:0::254
  - type: nameserver
    address:
      - 192.168.122.1
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
      $IPV4 $FQDN noc
      $IPV6 $FQDN noc
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
runcmd:
  - DEBIAN_FRONTEND=noninteractive fix-hostname $FQDN
  # Don't run any hostN containers, but prepare for cloning them in case they are desired.
  # They will be connected to external network and pick up IP address via DHCP.
  - lxc profile create br0
  - |
    lxc profile edit br0 <<EOS
    config:
      environment.http_proxy: ""
      user.network_mode: ""
    description: Bridged onto br0
    devices:
      eth0:
        name: eth0
        nictype: bridged
        parent: br0
        type: nic
      root:
        path: /
        pool: default
        type: disk
    EOS
  - lxc profile apply host-master br0
  - |
    lxc config set host-master user.user-data "\$(cat <<'END')"
    #cloud-config
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
      # Assume classroom server has virbr0 on standard address and apt-cacher-ng is available
      - path: /etc/apt/apt.conf.d/99proxy
        content: |
          Acquire::http::Proxy "http://192.168.122.1:3142/";
    final_message: Greetings from NSRC!
    END
final_message: NOC is ready!
EOS

yamllint -d relaxed "$TMPDIR/user-data"
yamllint -d relaxed "$TMPDIR/network-config"
OUTFILE="nocloud/noc-hdb.img"
rm -f "$OUTFILE"
cloud-localds -f vfat -d raw -H "$FQDN" -N "$TMPDIR/network-config" \
    "$OUTFILE" "$TMPDIR/user-data"
md5sum -b "$OUTFILE" | head -c32 >"$OUTFILE.md5sum"
ln "$OUTFILE" "nocloud/noc-hdb-${DATE}-$(head -c8 "$OUTFILE.md5sum").img"
ln "$OUTFILE.md5sum" "nocloud/noc-hdb-${DATE}-$(head -c8 "$OUTFILE.md5sum").img.md5sum"
rm "$OUTFILE" "$OUTFILE.md5sum"
