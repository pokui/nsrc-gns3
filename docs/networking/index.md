# Modify libvirt default network

libvirt will have created a default bridge called "virbr0" - you can see
this using `brctl show` or `ifconfig virbr0`.  Your server's address on this
bridge is `100.64.0.1`.

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
  <domain name='ws.nsrc.org' localOnly='yes'/>
  <ip address='100.64.0.1' netmask='255.255.252.0'>
    <dhcp>
      <range start='100.64.1.0' end='100.64.3.254'/>
    </dhcp>
  </ip>
  <ip family='ipv6' address='fe80::1' prefix='64'>
  </ip>
  <route address='100.64.0.0' prefix='10' gateway='100.64.0.254'/>
  <route family='ipv6' address='2001:db8::' prefix='32' gateway='fe80::254'/>
  <route family='ipv6' address='2001:10::' prefix='28' gateway='fe80::254'/>
</network>
```

Then save.  The change won't take effect until you reboot.

(The "domain" setting ensures that `*.ws.nsrc.org` names are only ever resolved
locally, and never forwarded to the public DNS)

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

Now plug in your USB3 adapter, and type `dmesg` and `ip link list` to
identify it.  It will probably get a name with its MAC address embedded,
like `enx00e04c063260`.  Copy this name: you'll need it shortly.

## Reconfigure netplan

Find your netplan config file.  It will be called
`/etc/netplan/<something>.yaml`

```
cd /etc/netplan
ls
```

Rename it so that it's no longer used, e.g.

```
sudo mv 01-netcfg.yaml 01-netcfg.yaml.disabled
```

If it was called `50-cloud-init.yaml` then also run the following command
to prevent it being regenerated:

```
echo "network: {config: disabled}" | sudo tee /etc/cloud/cloud.cfg.d/99-disable-network-config.cfg
```

Create a new file `/etc/netplan/10-wan.yaml`.  Include a configuration for
your new WAN interface, with DHCP enabled, and `optional: true` so that
booting is not delayed if it's not plugged in.

When you've finished, it should look like this, but with your WAN
interface name in place of `enx00e04c063260`:

```
network:
  version: 2
  ethernets:
    enx00e04c063260:
      dhcp4: true
      optional: true
```

!!! Note
    There should be *no* reference to "eno1" (or your LAN adapter) - that
    will be configured by a script instead.

If you need a static IP address on your WAN interface, see
[netplan examples](https://netplan.io/examples).

Normally you'd run `netplan generate; netplan apply` after changing the
configuration, but you will be rebooting shortly so don't bother.

## Attach eno1 to virbr0

To get eno1 attached to virbr0, you'll need to create a script
`/etc/libvirt/hooks/network` with the following contents:

```
#!/bin/bash
if [ "$1" = "default" -a "$2" = "started" ]; then
  /sbin/ip link set eno1 up
  # https://serverfault.com/questions/616485/e1000e-reset-adapter-unexpectedly-detected-hardware-unit-hang
  /sbin/ethtool -K eno1 gso off gro off tso off
  /sbin/brctl addif virbr0 eno1
  sysctl net.ipv4.conf.virbr0.accept_redirects=0
  sysctl net.ipv4.conf.virbr0.send_redirects=0
  iptables -I FORWARD -j ACCEPT -s 100.64.0.0/10 -i virbr0
  iptables -I FORWARD -j ACCEPT -d 100.64.0.0/10 -o virbr0 -m conntrack --ctstate RELATED,ESTABLISHED
  iptables -t nat -I POSTROUTING -j RETURN -o lo
  iptables -t nat -I POSTROUTING -j RETURN -o virbr0
  iptables -t nat -A POSTROUTING -j MASQUERADE -s 100.64.0.0/10 '!' -d 100.64.0.0/10
  ip6tables -I FORWARD -j ACCEPT -i virbr0
  ip6tables -I FORWARD -j ACCEPT -o virbr0 -m conntrack --ctstate RELATED,ESTABLISHED
  ip6tables -t nat -I POSTROUTING -j RETURN -o lo
  ip6tables -t nat -I POSTROUTING -j RETURN -o virbr0
  ip6tables -t nat -A POSTROUTING -j MASQUERADE -s 2001:db8::/32
  ip6tables -t nat -A POSTROUTING -j MASQUERADE -s 2001:10::/28
  ip6tables -t nat -A POSTROUTING -j MASQUERADE -s fc00::/7
fi
```

Ensure the script is executable:

```
sudo chmod +x /etc/libvirt/hooks/network
```

This script also enables NAT from the lab address space, plus it has a
workaround for [this problem](https://serverfault.com/questions/616485/e1000e-reset-adapter-unexpectedly-detected-hardware-unit-hang)
which can cause Intel NICs to lock up intermittently under high load, by
disabling TCP offloading.

## Reduce networking timeout

If the external interface is not connected, the server will take a long time
to boot (it will wait 2 to 5 minutes to try and pick up a DHCP address).
It's a good idea to reduce this timeout as follows:

```
sudo systemctl edit systemd-networkd-wait-online
```

This will put you into an editor.  Paste in the following:

```
[Service]
ExecStart=
ExecStart=/lib/systemd/systemd-networkd-wait-online --timeout=15
```

!!! Warning
    Make sure the capitalization is exactly correct

!!! Note
    The line which clears `ExecStart` is required.  This is because it is an
    [additive](https://askubuntu.com/questions/659267/how-do-i-override-or-configure-systemd-services)
    setting, but multiple values are not permitted other than for
    "OneShot" services

Exit and save.

<!--
For [older systems](https://unix.stackexchange.com/questions/186162/how-to-change-timeout-in-systemctl)
using "ifupdown" (e.g. Ubuntu 16.04) there's a different file:

```
sudo systemctl edit networking
```

and in the editor, write:

```
[Service]
TimeoutStartSec=15
```
-->

# Reboot and test

After all these changes, reboot:

```
sudo reboot
```

Connect your external Internet connection to the USB adapter.

You should find that:

- your server picks up an IP address via DHCP on its WAN (USB adapter)
- `brctl show` shows that eno1 is attached to the virbr0 bridge
- if you plug a laptop into the LAN port (eno1), it picks up a 100.64.0.x
  address and has Internet access via the server.  This will be your
  classroom (student) network
- still on the LAN port, ssh to 100.64.0.1 to get access to your server

That is: virbr0 is providing DHCP, DNS and NAT routing services to clients
connected to the LAN port.

If this doesn't work, then you will need to debug the problems with a
connected keyboard and screen before continuing.

Once this is working, you should be fine to go "headless" in future, since
you can get access to your server on the LAN port.

## Debugging: no virbr0

If you don't get a virbr0 on bootup, try the following command and see if
you get the error shown here:

```
$ virsh net-start default
error: Failed to start network default
error: internal error: Check the host setup: enabling IPv6 forwarding with RA routes without accept_ra set to 2 is likely to cause routes loss. Interfaces to look at: enx00e04c063260
```

The interface name should be your WAN interface.  See if this workaround
solves it:

```
sudo sysctl net.ipv6.conf.enx00e04c063260.accept_ra=2
virsh net-start default
```

The permanent solution is to create
`/etc/networkd-dispatcher/routable.d/accept-ra` with the following contents
(and make it executable) - replace `enx00e04c063260` with your WAN interface.

```
#!/bin/bash -eu
# https://superuser.com/questions/1208952/qemu-kvm-libvirt-forwarding
if [ "$IFACE" = "enx00e04c063260" ]; then
  sysctl net.ipv6.conf.enx00e04c063260.accept_ra=2
fi
```

# Classroom network

You can now connect the wireless access point and/or switch to the LAN port,
and your classroom network is up and running.

You should configure your access point with WPA2 and a trivial password. 
This is not so much for security, but to stop random passers-by from
automatically connecting to your class network.

To see all the active DHCP leases on your network:

```
virsh net-dhcp-leases default
```

Sorted by IP address:

```
virsh net-dhcp-leases default | sort -k4
```
