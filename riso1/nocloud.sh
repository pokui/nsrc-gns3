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

ETH0='ens3'
ETH1='ens4'
ETH2='ens5'
PASSWD='$6$e5ItKycG$AKYaEL8pZgSaedbBd4xJ1f0rTr9rDumjduQmo3qlOKWcLx/3WpojiyrWIulVXD1M3ImYMT5LSYnga94zlXPrG/'
PASSWD_INST='$6$znULAkk5$bkvmUKKtfX2h9vYxlUjbj2JRlRYkqQfiA7qoQGq7Tjy4MQeW4ewd2k5Ist.QFZmtzZkAxKZfuFQT3r.49U19W.'
: "${TMPDIR:=/tmp}"
DATE="$(date -u +%Y%m%d)"

mkdir -p nocloud
# SRVx
for i in $(seq 1 8); do
  FQDN="srv$i.ws.nsrc.org"
  IPV4="100.68.$i.30"
  GWV4="100.68.$i.29"
  IPV6="2001:db8:$i:21::30"
  GWV6="2001:db8:$i:21::29"
  BACKDOOR="192.168.122.$((10*i))"

  ######## NETWORK CONFIG ########
  cat <<EOS >"$TMPDIR/network-config"
version: 2
ethernets:
  $ETH0:
    accept-ra: false
    addresses:
      - $IPV4/30
      - $IPV6/64
    gateway4: $GWV4
    gateway6: $GWV6
  $ETH1:
    accept-ra: false
    addresses:
      - $BACKDOOR/24
    nameservers:
      addresses:
        - 192.168.122.1
      search:
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
  - name: isplab
    gecos: Student
    groups: [adm, audio, cdrom, dialout, dip, floppy, lxd, netdev, plugdev, sudo, video]
    lock_passwd: false
    passwd: $PASSWD
    shell: /bin/bash
write_files:
  - path: /etc/hosts
    content: |
      $IPV4 $FQDN srv$i
      $IPV6 $FQDN srv$i
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
  # Policy routing so inbound traffic to 192.168.122.x always returns via same interface
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
        ip route add default via 192.168.122.1 dev $ETH1 metric 100 table backdoor
        ip route add 192.168.122.0/24 dev $ETH1  proto kernel  scope link  src $BACKDOOR  table backdoor
        ip route flush cache
      fi
  - path: /etc/sysctl.d/90-rpf.conf
    content: |
      # Loose reverse path filtering (traffic from 192.168.122 address may come in via $ETH0)
      net.ipv4.conf.all.rp_filter=2
runcmd:
  - IFACE=$ETH1 /etc/networkd-dispatcher/routable.d/50-backdoor
  - sysctl -p /etc/sysctl.d/90-rpf.conf
final_message: NSRC welcomes you to Routing Security!
EOS
  yamllint "$TMPDIR/user-data"
  yamllint "$TMPDIR/network-config"
  OUTFILE="nocloud/riso-srv${i}-hdb.img"
  rm -f "$OUTFILE"
  cloud-localds -f vfat -d raw -H "$FQDN" -N "$TMPDIR/network-config" \
      "$OUTFILE" "$TMPDIR/user-data"
  md5sum -b "$OUTFILE" | head -c32 >"$OUTFILE.md5sum"
  ln "$OUTFILE" "nocloud/riso-srv${i}-hdb-${DATE}-$(head -c8 "$OUTFILE.md5sum").img"
  ln "$OUTFILE.md5sum" "nocloud/riso-srv${i}-hdb-${DATE}-$(head -c8 "$OUTFILE.md5sum").img.md5sum"
  rm "$OUTFILE" "$OUTFILE.md5sum"
done

# RSx
for i in $(seq 1 2); do
  FQDN="rs$i.ws.nsrc.org"
  SR_AS="$(( 130 + i ))"
  V6DEC="$(( 65536 - i ))"
  V6BLOCK="2001:DB8:`printf "%04X" "$V6DEC"`"
  V4SRV="100.127.$(( (i-1)*2 ))"
  V4IXP="100.127.$(( (i-1)*2+1 ))"
  IPV4="${V4SRV}.10"
  GWV4="${V4SRV}.9"
  IPV6="${V6BLOCK}:2::10"
  GWV6="${V6BLOCK}:2::9"
  IPV4_IXP="${V4IXP}.254"
  IPV6_IXP="${V6BLOCK}:1::FE"
  BACKDOOR="192.168.122.$((i+4))"

  ######## NETWORK CONFIG ########
  cat <<EOS >"$TMPDIR/network-config"
version: 2
ethernets:
  $ETH0:
    accept-ra: false
    addresses:
      - $IPV4/29
      - $IPV6/64
    gateway4: $GWV4
    gateway6: $GWV6
  $ETH1:
    accept-ra: false
    addresses:
      - $IPV4_IXP/24
      - $IPV6_IXP/64
  $ETH2:
    accept-ra: false
    addresses:
      - $BACKDOOR/24
    nameservers:
      addresses:
        - 192.168.122.1
      search:
        - ws.nsrc.org
EOS

  ######## USER DATA ########
  # This configures all other aspects of boot, including creating user/password.
  (
  cat <<EOS
#cloud-config
fqdn: $FQDN
chpasswd: { expire: False }
ssh_pwauth: True
users:
  - name: isplab
    gecos: Student
    groups: [bird]
    lock_passwd: false
    passwd: $PASSWD
    shell: /bin/bash
  - name: nsrc
    gecos: Instructor
    groups: [adm, audio, bird, cdrom, dialout, dip, floppy, lxd, netdev, plugdev, sudo, video]
    lock_passwd: false
    passwd: $PASSWD_INST
    shell: /bin/bash
write_files:
  - path: /etc/hosts
    content: |
      $IPV4 $FQDN rs$i
      $IPV6 $FQDN rs$i
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
  # Policy routing so inbound traffic to 192.168.122.x always returns via same interface
  - path: /etc/iproute2/rt_tables
    append: true
    content: |
      150	backdoor
  - path: /etc/networkd-dispatcher/routable.d/50-backdoor
    permissions: '0755'
    content: |
      #!/bin/bash
      if [ "\$IFACE" = "$ETH2" ]; then
        # Apply policy routing
        ip rule add from $BACKDOOR table backdoor
        ip route add default via 192.168.122.1 dev $ETH2 metric 100 table backdoor
        ip route add 192.168.122.0/24 dev $ETH2  proto kernel  scope link  src $BACKDOOR  table backdoor
        ip route flush cache
      fi
  - path: /etc/sysctl.d/90-rpf.conf
    content: |
      # Loose reverse path filtering (traffic from 192.168.122 address may come in via $ETH0/$ETH1)
      net.ipv4.conf.all.rp_filter=2
  - path: /etc/bird/bird.conf
    owner: bird:bird
    permissions: '0640'
    content: |
      # This configuration based on:
      # https://gitlab.labs.nic.cz/labs/bird/-/wikis/Simple_route_server
      # https://gitlab.labs.nic.cz/labs/bird/-/wikis/transition-notes-to-bird-2
      # https://github.com/pierky/arouteserver/blob/master/examples/default/bird_v2.conf
      #
      # For more options see:
      # /usr/share/doc/bird2/examples/bird.conf
      # https://bird.network.cz/?get_doc&f=bird.html&v=20

      log "/var/log/bird/bird.log" all;
      #log syslog all;

      router id ${V4IXP}.254;
      define myas = $(( 65535 - i ));

      protocol device { }

      # This function returns True if 'net' is a bogon prefix
      # or falls within a bogon prefix.

      function prefix_is_bogon()
      prefix set bogons_4;
      prefix set bogons_6;
      {
              bogons_4 = [
                      # Default route
                      0.0.0.0/0,

                      # IANA - Local Identification
                      0.0.0.0/8{8,32},

                      # RFC 1918 - Private Use
                      10.0.0.0/8{8,32},

                      # IANA - Loopback
                      127.0.0.0/8{8,32},

                      # RFC 6598 - Shared Address Space
                      # NSRC: commented out as we use this
                      # 100.64.0.0/10{10,32},

                      # RFC 3927 - Link Local
                      169.254.0.0/16{16,32},

                      # RFC 1918 - Private Use
                      172.16.0.0/12{12,32},

                      # RFC 5737 - TEST-NET-1
                      192.0.2.0/24{24,32},

                      # RFC 3068 - 6to4 prefix
                      192.88.99.0/24{24,32},

                      # RFC 1918 - Private Use
                      192.168.0.0/16{16,32},

                      # RFC 2544 - Network Interconnect Device Benchmark Testing
                      198.18.0.0/15{15,32},

                      # RFC 5737 - TEST-NET-2
                      198.51.100.0/24{24,32},

                      # RFC 5737 - TEST-NET-3
                      203.0.113.0/24{24,32},

                      # RFC 5771 - Multicast (formerly Class D) and Class E
                      224.0.0.0/3{3,32}
              ];
              bogons_6 = [
                      # Default route
                      ::/0,

                      # loopback, unspecified, v4-mapped
                      ::/8{8,128},

                      # RFC 6052 - IPv4-IPv6 Translation
                      64:ff9b::/96{96,128},

                      # RFC 6666 - reserved for Discard-Only Address Block
                      100::/8{8,128},

                      # RFC 4048 - Reserved by IETF
                      200::/7{7,128},

                      # RFC 4291 - Reserved by IETF
                      400::/6{6,128},

                      # RFC 4291 - Reserved by IETF
                      800::/5{5,128},

                      # RFC 4291 - Reserved by IETF
                      1000::/4{4,128},

                      # RFC 4380 - Teredo prefix
                      2001::/32{32,128},

                      # RFC 5180 - Benchmarking
                      2001:2::/48{48,128},

                      # RFC 7450 - Automatic Multicast Tunneling
                      2001:3::/32{32,128},

                      # RFC 4843 - Deprecated ORCHID
                      # NSRC: commented out as we use 2001:18::/31
                      # 2001:10::/28{28,128},

                      # RFC 7343 - ORCHIDv2
                      2001:20::/28{28,128},

                      # RFC 3849 - NON-ROUTABLE range to be used for documentation purpose
                      # NSRC: commented out as we use it
                      # 2001:db8::/32{32,128},

                      # RFC 3068 - 6to4 prefix
                      2002::/16{16,128},

                      # RFC 5156 - used for the 6bone but was returned
                      3ffe::/16{16,128},

                      # RFC 4291 - Reserved by IETF
                      4000::/2{2,128},

                      # RFC 4291 - Reserved by IETF
                      8000::/1{1,128}
              ];

              if net.type = NET_IP4 then
                      if net ~ bogons_4 then return true;
              if net.type = NET_IP6 then
                      if net ~ bogons_6 then return true;
              return false;
      }

      ####
      # Protocol template

      template bgp PEERS {
        local as myas;
        rs client;
      }


      ####
      # Configuration of BGP peer follows

      ###
      filter bgp_in_AS${SR_AS}
      prefix set allnet;
      int set allas;
      {
        if (prefix_is_bogon()) then reject;
        if (bgp_path.first != ${SR_AS} ) then reject;

        allas = [ ${SR_AS} ];
        if ! (bgp_path.last ~ allas) then reject;

        allnet = [ ${V4SRV}.0/24, ${V6BLOCK}::/48 ];
        if ! (net ~ allnet) then reject;

        accept;
      }

      protocol bgp SR${i}v4 from PEERS {
        description "SR${i} - IPv4";
        neighbor ${V4IXP}.253 as ${SR_AS};
        password "ixp-rs";
        ipv4 {
          import filter bgp_in_AS${SR_AS};
          import limit 10000 action restart;
          export all;
        };
      }

      protocol bgp SR${i}v6 from PEERS {
        description "SR${i} - IPv6";
        neighbor ${V6BLOCK}:1::FD as ${SR_AS};
        password "ixp-rs";
        ipv6 {
          import filter bgp_in_AS${SR_AS};
          import limit 10000 action restart;
          export all;
        };
      }

EOS
  for GROUP in $(seq $((i*4-3)) $((i*4))); do
    AS=$((GROUP*10))
    OTHER=$(( ((GROUP-1)^1)+1 ))
    cat <<EOS

      ### AS${AS} - Group ${GROUP}
      filter bgp_in_AS${AS}
      prefix set allnet;
      int set allas;
      {
        if (prefix_is_bogon()) then reject;
        if (bgp_path.first != ${AS} ) then reject;

        allas = [ ${AS}, $(( GROUP*10 + 100000 )), $(( OTHER*10 + 100000 )) ];
        if ! (bgp_path.last ~ allas) then reject;

        allnet = [ 100.68.${GROUP}.0/24, 100.68.$(( GROUP+100 )).0/24, 100.68.$(( OTHER+100 )).0/24,
                   2001:DB8:${GROUP}::/48, 2001:DB8:$(( GROUP+100 ))::/48, 2001:DB8:$(( OTHER+100 ))::/48 ];
        if ! (net ~ allnet) then reject;

        accept;
      }

      protocol bgp R${AS}v4 from PEERS {
        description "Group ${GROUP} - IPv4";
        neighbor ${V4IXP}.${GROUP} as ${AS};
        password "ixp-rs";
        ipv4 {
          import filter bgp_in_AS${AS};
          import limit 10000 action restart;
          export all;
        };
      }

      protocol bgp R${AS}v6 from PEERS {
        description "Group ${GROUP} - IPv6";
        neighbor ${V6BLOCK}:1::${GROUP} as ${AS};
        password "ixp-rs";
        ipv6 {
          import filter bgp_in_AS${AS};
          import limit 10000 action restart;
          export all;
        };
      }

EOS
  done
  cat <<EOS
  # Quick hack to reduce student interference
  # Beware that write_files and runcmd take place before users are created:
  # https://bugs.launchpad.net/cloud-init/+bug/1486113
  - path: /etc/profile.d/bird.sh
    content: |
      if ! expr "\$(groups)" : '.*sudo' >/dev/null; then
        alias birdc="/usr/sbin/birdc -r"
        alias birdcl="/usr/sbin/birdcl -r"
      fi
runcmd:
  - IFACE=$ETH2 /etc/networkd-dispatcher/routable.d/50-backdoor
  - sysctl -p /etc/sysctl.d/90-rpf.conf
  - mkdir -p /var/log/bird
  # Workaround for http://trubka.network.cz/pipermail/bird-users/2020-April/014509.html
  - touch /var/log/bird/bird.log; chown bird:bird /var/log/bird/bird.log
  - systemctl enable bird
  - systemctl start bird
final_message: NSRC welcomes you to Routing Security!
EOS
  ) >"$TMPDIR/user-data"
  yamllint "$TMPDIR/user-data"
  yamllint "$TMPDIR/network-config"
  OUTFILE="nocloud/riso-rs${i}-hdb.img"
  rm -f "$OUTFILE"
  cloud-localds -f vfat -d raw -H "$FQDN" -N "$TMPDIR/network-config" \
      "$OUTFILE" "$TMPDIR/user-data"
  md5sum -b "$OUTFILE" | head -c32 >"$OUTFILE.md5sum"
  ln "$OUTFILE" "nocloud/riso-rs${i}-hdb-${DATE}-$(head -c8 "$OUTFILE.md5sum").img"
  ln "$OUTFILE.md5sum" "nocloud/riso-rs${i}-hdb-${DATE}-$(head -c8 "$OUTFILE.md5sum").img.md5sum"
  rm "$OUTFILE" "$OUTFILE.md5sum"
done
