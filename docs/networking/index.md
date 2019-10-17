# Install virsh/libvirt

GNS3 networking requires the bridge "virbr0" set up by virsh/libvirt.  So
install it:

```
sudo apt-get install virsh
```

This should install a number of packages as dependencies, including
bridge-utils, libvirt and qemu.

Now logout and log back in again as the "nsrc" user.  Check that you are in
the "kvm" and "libvirtd" groups using the `id` command:

```
nsrc@brian-kit:~$ id
uid=1000(nsrc) gid=1000(nsrc) groups=1000(nsrc), ... 117(kvm),118(libvirtd)
```

(the actual numbers may be different).  If not, then add yourself to these
groups:

```
sudo usermod -a -G kvm,libvirtd nsrc
```

Logout and login again, and check with `id` again.

# Modify libvirt default network

libvirt will have created a default bridge called "virbr0" - you can see
this using `brctl show` or `ifconfig virbr0`.  Your server's address on this
bridge is `192.168.122.1`.

You now need to change its configuration, to shrink the DHCP pool range and
add a static route.

Use the following command to edit the network definition XML:

```
virsh net-edit default
```

Edit it so it looks like this (leave the sections marked `....` alone):

```
<network>
  <name>default</name>
  <uuid>....</uuid>
  <forward mode='nat'>
    <nat>
      <port start='1024' end='65535'/>
    </nat>
  </forward>
  <bridge name='virbr0' stp='off' delay='0'/>
  <mac address='....'/>
  <ip address='192.168.122.1' netmask='255.255.255.0' localPtr='yes'>
    <dhcp>
      <range start='192.168.122.100' end='192.168.122.249'/>
    </dhcp>
  </ip>
  <route address='100.64.0.0' prefix='10' gateway='192.168.122.254'/>
</network>
```

Then save.  The change won't take effect until you reboot.

# Reconfigure external ports

You are now going to reconfigure the platform so that the LAN interface
connects to virbr0, and your other ethernet port (e.g. the USB3-attached
NIC) is your WAN connection.

## Identify your LAN interface

Currently, you're probably using your LAN interface for your external
Internet access.  On the Intel NUCs this is `eno1`; for a Mac it may be
different.

Type `ipconfig -a` or `ip link list` to get a list of interfaces on your
system.  If it's not "eno1" then substitute the correct interface in the
following instructions as required.

## Identify your WAN interface

Now plug in your USB3 adapter, and type `dmesg` or `ip link list` to
identify it.  It will probably get a name with its MAC address embedded,
like `enx00e04c063260`.  Copy this name: you'll need it shortly.

## Reconfigure netplan

Find your netplan config file.  It may be called something like
`/etc/netplan/1-netplan.yml`

```
cd /etc/netplan
ls
```

Edit this file and *remove* all references to "eno1" (or your LAN adapter).
They'll be configured by a script instead.

*Add* a configuration for your new interface, with DHCP enabled.

When you've finished, it should look like this:

```
network:
  version: 2
  ethernets:
    enx086d41e68ba8:
      dhcp4: true
      optional: true
```

If you need a static IP address on your WAN interface, see
[netplan examples](https://netplan.io/examples).

## Attach eno1 to virbr0

To get eno1 attached to virbr0, you'll need to create a script
`/etc/libvirt/hooks/network` with the following contents:

```
#!/bin/bash
if [ "$1" = "default" -a "$2" = "started" ]; then
  /sbin/ip link set eno1 up
  /sbin/brctl addif virbr0 eno1
  iptables -I FORWARD -j ACCEPT -s 100.64.0.0/10 -i virbr0
  iptables -I FORWARD -j ACCEPT -d 100.64.0.0/10 -o virbr0 -m conntrack --ctstate RELATED,ESTABLISHED
  iptables -t nat -A POSTROUTING -j MASQUERADE -s 100.64.0.0/10 '!' -d 100.64.0.0/10
fi
```

Ensure the script is executable:

```
sudo chmod +x /etc/libvirt/hooks/network
```

This script also enables NAT from the lab address space.

## Workaround for Intel NIC bug

If you have an Intel LAN adapter, then it probably suffers from
[this problem](https://serverfault.com/questions/616485/e1000e-reset-adapter-unexpectedly-detected-hardware-unit-hang)
which causes it to lock up intermittently under high load.

Newer kernels (5.0+) apparently don't have this problem, but until then you
can workaround it by disabling checksum offloading.  Create a file
`/etc/networkd-dispatcher/configuring.d/10-intel-fix` with the following
contents:

```
#!/bin/sh
# https://serverfault.com/questions/616485/e1000e-reset-adapter-unexpectedly-detected-hardware-unit-hang
if [ "$IFACE" = "eno1" ]; then
  /sbin/ethtool -K eno1 gso off gro off tso off
fi
```

Again, make this executable:

```
sudo chmod +x /etc/networkd-dispatcher/configuring.d/10-intel-fix
```

(For Ubuntu 16.04, create this file as `/etc/network/if-pre-up.d/10-intel-fix` instead)

# Reboot and test

After all these changes, reboot:

```
sudo reboot
```

Connect your external Internet connection to the USB adapter.

You should find that:

- your server picks up an IP address via DHCP on its WAN (USB adapter)
- `brctl show` shows that eno1 is attached to the virbr0 bridge
- if you plug a laptop into the LAN port (eno1), it picks up a 192.168.122.x
  address and has Internet access via the server.  This will be your
  classroom (student) network
- still on the LAN port, ssh to 192.168.122.1 to get access to your server

That is: virbr0 is providing DHCP, DNS and NAT routing services to clients
connected to the LAN port.

If this doesn't work, then you will need to debug the problems with a
connected keyboard and screen before continuing.

Once this is working, you should be fine to go "headless" in future, since
you can get access to your server on the LAN port.

# Classroom network

You can now connect the wireless access point and/or switch to the LAN port,
and your classroom network is up and running.

You should configure your access point with WPA2 and a trivial password. 
This is not so much for security, but to stop random passers-by from
automatically connecting to your class network.

# Optional: Wireless uplink

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
"links" or "elinks"
