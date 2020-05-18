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
ETH1='ens4'
PASSWD='$6$XqBb4pf3$rTN75u32r30VDbY252DwLLJ0rAuxIMvZceX02YFXK/WjAJ0FVjrUCQSkdPWA7nW0DoSNJrdu9w.PGOLbZmWlb/'
: "${TMPDIR:=/tmp}"
DATE="$(date -u +%Y%m%d)"

mkdir -p nocloud
for i in $(seq 1 6); do
  FQDN="srv1.campus$i.ws.nsrc.org"
  IPV4="100.68.$i.130"
  IPV6="2001:db8:$i:1::130"
  BACKDOOR="192.168.122.$((10*i))"

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
        gateway: 100.68.$i.129
      - type: static
        address: $IPV6/64
        gateway: 2001:db8:$i:1::1
  - type: physical
    name: $ETH1
  - type: bridge
    name: br1
    bridge_interfaces:
      - $ETH1
    params:
      bridge_fd: 0
      bridge_maxwait: 0
      bridge_stp: 'off'
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
      Acquire::http::Proxy "http://192.168.122.1:3142/";
  - path: /etc/network/if-pre-up.d/fix-v6-gateway
    permissions: '0755'
    content: |
      #!/bin/sh
      # Fix for v6 default gateway picked up from RA then vanishing after 30 minutes
      if [ "\$IFACE" = "br0" ]; then
        sysctl net.ipv6.conf.br0.accept_ra=0
        ip -6 route delete ::/0 dev br0 || true
      fi
  # Policy routing so inbound traffic to 192.168.122.x always returns via same interface
  - path: /etc/iproute2/rt_tables
    append: true
    content: |
      150	backdoor
  - path: /etc/networkd-dispatcher/routable.d/50-backdoor
    permissions: '0755'
    content: |
      #!/bin/bash
      if [ "\$IFACE" = "br1" ]; then
        # Apply policy routing
        ip rule add from $BACKDOOR table backdoor
        ip route add default via 192.168.122.1 dev br1 metric 100 table backdoor
        ip route add 192.168.122.0/24 dev br1  proto kernel  scope link  src $BACKDOOR  table backdoor
        ip route flush cache
      fi
  - path: /etc/sysctl.d/90-rpf.conf
    content: |
      # Loose reverse path filtering (traffic from 192.168.122 address may come in via br0)
      net.ipv4.conf.all.rp_filter=2
runcmd:
  # Fixup https repositories to use proxy
  - sed -i -e 's#https://#http://HTTPS///#' /etc/apt/sources.list /etc/apt/sources.list.d/*.list
  # YAML doesn't need escaping of backslash, but shell (cat <<EOS) does
  - sed -i'' -r -e 's#(\\\\h)([^.])#\\1.campus$i\\2#g' /etc/profile /etc/bash.bashrc /etc/skel/.bashrc /root/.bashrc /home/*/.bashrc
  - DEBIAN_FRONTEND=noninteractive fix-hostname $FQDN
  - '[ -d /etc/network/if-up.d ] && ln -s /etc/networkd-dispatcher/routable.d/50-backdoor /etc/network/if-up.d/backdoor'
  - IFACE=br1 /etc/networkd-dispatcher/routable.d/50-backdoor
  - sysctl -p /etc/sysctl.d/90-rpf.conf
  - lxc profile create bridged
  - |
    lxc profile edit bridged <<EOS
    config:
      environment.http_proxy: ""
      user.network_mode: ""
    description: Bridged external and out-of-band
    devices:
      eth0:
        name: eth0
        nictype: bridged
        parent: br0
        type: nic
      eth1:
        name: eth1
        nictype: bridged
        parent: br1
        type: nic
      root:
        path: /
        pool: default
        type: disk
    EOS
  - lxc profile apply host-master bridged
  - |
    # Encrypted password contains dollar signs, so delay its evaluation
    PASSWD='$PASSWD'
    for h in \$(seq 1 6); do
      HOST_FQDN="host\$h.campus$i.ws.nsrc.org"
      HOST_BACKDOOR="192.168.122.\$((10*$i + h))"
      lxc copy host-master host\$h -c user.network-config="\$(cat <<END1)" -c user.user-data="\$(cat <<END2)"
    version: 1
    config:
      - type: physical
        name: eth0
        subnets:
          - type: static
            address: 100.68.$i.\$((130 + h))/28
            gateway: 100.68.$i.129
          - type: static
            address: 2001:db8:$i:1::\$((130 + h))/64
            gateway: 2001:db8:$i:1::1
      - type: physical
        name: eth1
        subnets:
          - type: static
            address: \$HOST_BACKDOOR/24
      - type: nameserver
        address:
          - 192.168.122.1
        search:
          - campus$i.ws.nsrc.org
          - ws.nsrc.org
    END1
    #cloud-config
    chpasswd: { expire: False }
    ssh_pwauth: True
    users:
      - name: sysadm
        gecos: Student System Administrator
        groups: [adm, audio, cdrom, dialout, dip, floppy, lxd, netdev, plugdev, sudo, video]
        lock_passwd: false
        passwd: \$PASSWD
        shell: /bin/bash
    write_files:
      # Assume classroom server has virbr0 on standard address and apt-cacher-ng is available
      - path: /etc/apt/apt.conf.d/99proxy
        content: |
          Acquire::http::Proxy "http://192.168.122.1:3142/";
      - path: /etc/network/if-pre-up.d/fix-v6-gateway
        permissions: '0755'
        content: |
          #!/bin/sh
          # Fix for v6 default gateway picked up from RA then vanishing after 30 minutes
          if [ "\\\$IFACE" = "eth0" ]; then
            sysctl net.ipv6.conf.eth0.accept_ra=0
            ip -6 route delete ::/0 dev eth0 || true
          fi
      # Policy routing so inbound traffic to 192.168.122.x always returns via same interface
      - path: /etc/iproute2/rt_tables
        append: true
        content: |
          150	backdoor
      - path: /etc/networkd-dispatcher/routable.d/50-backdoor
        permissions: '0755'
        content: |
          #!/bin/bash
          if [ "\\\$IFACE" = "eth1" ]; then
            # Apply policy routing
            ip rule add from \$HOST_BACKDOOR table backdoor
            ip route add default via 192.168.122.1 dev eth1 metric 100 table backdoor
            ip route add 192.168.122.0/24 dev eth1  proto kernel  scope link  src \$HOST_BACKDOOR  table backdoor
            ip route flush cache
          fi
      - path: /etc/sysctl.d/90-rpf.conf
        content: |
          # Loose reverse path filtering (traffic from 192.168.122 address may come in via eth0)
          net.ipv4.conf.all.rp_filter=2
    runcmd:
      # Fixup https repositories to use proxy
      - sed -i -e 's#https://#http://HTTPS///#' /etc/apt/sources.list /etc/apt/sources.list.d/*.list
      # Additional level of escaping required
      - sed -i'' -r -e 's#(\\\\\\\\h)([^.])#\\\\1.campus$i\\\\2#g' /etc/profile /etc/bash.bashrc /etc/skel/.bashrc /root/.bashrc /home/*/.bashrc
      - DEBIAN_FRONTEND=noninteractive fix-hostname \$HOST_FQDN
      - '[ -d /etc/network/if-up.d ] && ln -s /etc/networkd-dispatcher/routable.d/50-backdoor /etc/network/if-up.d/backdoor'
      # Network was initialized early in boot, so on first run we have to apply the fixes again
      - IFACE=eth0 /etc/network/if-pre-up.d/fix-v6-gateway || true; ifdown eth0 || true; ifconfig eth0 0.0.0.0 down; ifup eth0
      - IFACE=eth1 /etc/networkd-dispatcher/routable.d/50-backdoor
      - sysctl -p /etc/sysctl.d/90-rpf.conf
    END2
      lxc start host\$h
    done
final_message: NSRC welcomes you to NMM!
EOS
  yamllint -d relaxed "$TMPDIR/user-data"
  yamllint -d relaxed "$TMPDIR/network-config"
  OUTFILE="nocloud/nmm-srv1-campus${i}-hdb.img"
  rm -f "$OUTFILE"
  cloud-localds -f vfat -d raw -H "$FQDN" -N "$TMPDIR/network-config" \
      "$OUTFILE" "$TMPDIR/user-data"
  md5sum -b "$OUTFILE" | head -c32 >"$OUTFILE.md5sum"
  ln "$OUTFILE" "nocloud/nmm-srv1-campus${i}-hdb-${DATE}-$(head -c8 "$OUTFILE.md5sum").img"
  ln "$OUTFILE.md5sum" "nocloud/nmm-srv1-campus${i}-hdb-${DATE}-$(head -c8 "$OUTFILE.md5sum").img.md5sum"
  rm "$OUTFILE" "$OUTFILE.md5sum"
done