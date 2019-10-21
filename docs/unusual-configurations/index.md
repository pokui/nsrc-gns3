Here are some hints on some special-case scenarios.

# Running the NMM VM outside GNS3

The NOC/NMM VM does not have to be run inside GNS3 - it can run in other
virtualisation environments too.  For example, you can run it in a cloud
environment, or students should be able to run it directly in Virtualbox or
VMWare Player on their laptops.

(TODO: There seems to be an issue with VirtualBox which prevents it
detecting the qcow2 image as bootable)

The image has no hard-coded login credentials, so you either need to run it
in an environment which supports cloud-init natively, or you have to provide
it with a second disk drive image with cloud-init files.  Otherwise you'll
find you have no way to login to it once it has started.

We provide an alternate cloud-init image,
`nsrc-nmm-nocloud-hdb-<version>.img`, which contains no network config so it
will configure itself using DHCP.  This should work in most VM environments. 
It just contains configuration to create the `sysadm` user account.

This image is a small MSDOS filesystem, which can be mounted easily on many
types of system, or edited using `mtools` under Linux.

We distribute it as a raw image because it's the easiest to mount and
modify.  Note that VirtualBox doesn't work with raw images, so you may have
to convert it first to some other format that it accepts: e.g.

```
qemu-img convert -O vdi nsrc-nmm-nocloud-hdb-20191016-d389944a.img nsrc-nmm-nocloud-hdb-20191016-d389944a.vdi
```

# Wireless uplink

In some environments, you may find that your server's Internet uplink needs
to be via an existing wireless network (e.g.  in a hotel with no wired
ethernet port)

To do this, create a file like `/etc/netplan/50-wifi.yaml` containing the
configuration(s) for the wireless network(s) you want to use.

```
network:
  version: 2
  wifis:
    wlp3s0:
      dhcp4: true
      optional: true
      access-points:
        "OpenNetwork1": {}
        "OpenNetwork2": {}
        "SomeSecureNetwork":
          password: "abcd1234"
```

To activate it:

```
sudo netplan generate
sudo netplan apply
```

See [netplan examples](https://netplan.io/examples) for more options.

You can rename this file, e.g. to `/etc/netplan/50-wifi.yaml.disabled`, when
you don't want any wifi connection to be attempted.

Some environments will require you to authenticate to a captive portal
before you get Internet access.  As long as your laptop is connected on the
classroom side (192.168.122.x) it should be able to access the portal. 
Alternatively you could try installing a text-based browser like "lynx",
"links" or "elinks".

# Inbound access from site network

In some rare cases you might want to allow inbound access to your labs from
the WAN-side network - for example, students are on an existing in-building
wifi network.

```no-highlight
                         rtr --> Internet
                          |
--------+----------+-+-+--+-
        |          | | |
     WAN|          Users
   +--------+
   | Server |
   +--------+
     LAN|
 -------+--
```

To make this happen:

1. In the external site infrastructure ("rtr"), add static routes to

    * 192.168.122.0/24
    * 100.64.0.0/10

    with your server's WAN address as the next hop

2. In your server, extend `/etc/libvirt/hooks/network` to allow
   access from the new range.  For example, say the users are
   on `10.20.30.0/24`:

```
#!/bin/bash
if [ "$1" = "default" -a "$2" = "started" ]; then
  /sbin/ip link set eno1 up
  /sbin/brctl addif virbr0 eno1
  iptables -I FORWARD -j ACCEPT -s 100.64.0.0/10 -i virbr0
  iptables -I FORWARD -j ACCEPT -d 100.64.0.0/10 -o virbr0 -m conntrack --ctstate RELATED,ESTABLISHED
  iptables -t nat -A POSTROUTING -j MASQUERADE -s 100.64.0.0/10 '!' -d 100.64.0.0/10
  #### ADD: Accept inbound from trusted source
  iptables -I FORWARD -s 10.20.30.0/24 -j ACCEPT
fi
```

This works as long as there is no intervening NAT.  However, users will not
be able to resolve the entries in your DNS.

# apt-cacher-ng SSL/TLS passthrough

The student VMs are configured to make all requests via the apt-cacher-ng
proxy.  If any of them try to access repositories with `https` URLs, the
proxy will not permit it.  Note that this will only affect you if you've
asked students to add custom package repositories.

There are various [workarounds](https://blog.packagecloud.io/eng/2015/05/05/using-apt-cacher-ng-with-ssl-tls/#caching-objects):

(1) Permit all SSL/TLS through the proxy

In `/etc/apt-cacher-ng/acng.conf`

```
PassThroughPattern: .*
```

This allows https connections to pass through the proxy.  However,
packages will *not* be cached.

(2) Permit specific URLs through the proxy

Example:

```
PassThroughPattern: ^(packagecloud\.io|packagecloud-repositories\.s3\.dualstack\.us-west-1\.amazonaws\.com|packagecloud-prod\.global\.ssl\.fastly\.net|d28dx6y1hfq314\.cloudfront\.net|download\.docker\.com|packages\.grafana\.com|changelogs\.ubuntu\.com|packages\.fluentbit\.io):443$`
```

Similar, and slightly more secure as you can control which repos can be
reached - but packages are still not cached.

(3) Students configure special-form URLs

```
# Instead of: deb https://download.docker.com/linux/ubuntu xenial stable

deb http://HTTPS///download.docker.com/linux/ubuntu xenial stable
```

This should be a better solution, as it allows the packages to be cached.
