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

mkdir -p cndo/nocloud
for i in $(seq 1 6); do
  FQDN="srv1.campus$i.ws.nsrc.org"
  IPV4="100.68.$i.130"
  IPV6="2001:db8:$i:1::130"
  BACKDOOR="192.168.122.$((i+220))"

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
  # Script clones the hostN containers and configures *their* networking and users too.
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
  # Policy routing so inbound traffic to 192.168.122.x always returns via same interface
  - path: /etc/iproute2/rt_tables
    append: true
    content: |
      150	backdoor
  # For ifupdown-based system
  - path: /etc/network/if-up.d/backdoor
    permissions: '0755'
    content: |
      #!/bin/bash
      if [ "\$IFACE" = "$ETH1" ]; then
        # Apply policy routing
        ip rule add from $BACKDOOR table backdoor
        ip route add default via 192.168.122.1 dev $ETH1 metric 100 table backdoor
        ip route add 192.168.122.0/24 dev $ETH1  proto kernel  scope link  src $BACKDOOR  table backdoor
        ip route flush cache
      fi
  # For netplan-based system
  - path: /etc/networkd-dispatcher/routable.d/50-backdoor
    permissions: '0755'
    content: |
      #!/bin/bash
      if [ "\$IFACE" = "$ETH1" ]; then
        # Apply policy routing
        ip rule add from $BACKDOOR table backdoor
        ip route add default via 192.168.122.1 dev $ETH1 metric 100 table backdoor
        ip route add 192.168.122.0/24 dev $ETH1  proto kernel  scope link  src $BACKDOOR  table backdoor
        ip route flush cache
      fi
runcmd:
  - fix-hostname $FQDN
  - lxc profile apply host-master br0
  - |
    # Encrypted password contains dollar signs, so delay its evaluation
    PASSWD='$PASSWD'
    for h in \$(seq 1 6); do
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
    runcmd:
      - fix-hostname host\$h.campus$i.ws.nsrc.org
    END2
      lxc start host\$h
    done
final_message: NSRC welcomes you to CNDO!
EOS
  yamllint -d relaxed "$TMPDIR/user-data"
  yamllint -d relaxed "$TMPDIR/network-config"
  OUTFILE="cndo/nocloud/srv1-campus${i}-hdb.img"
  rm -f "$OUTFILE"
  cloud-localds -f vfat -d raw -H "$FQDN" -N "$TMPDIR/network-config" \
      "$OUTFILE" "$TMPDIR/user-data"
  ln "$OUTFILE" "cndo/nocloud/srv1-campus${i}-hdb-${DATE}-$(md5sum -b "$OUTFILE" | head -c8).img"
  rm "$OUTFILE"
done
