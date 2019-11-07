# Install virsh/libvirt

GNS3 networking requires the bridge "virbr0" set up by virsh/libvirt.
Install it:

```
sudo apt-get install libvirt-daemon-system bridge-utils
```

This should install a number of packages as dependencies, including
qemu-kvm.

Now logout and log back in again as the "nsrc" user.  Check that you are in
the "kvm" and "libvirt" groups using the `id` command:

```
nsrc@brian-kit:~$ id
uid=1000(nsrc) gid=1000(nsrc) groups=1000(nsrc), ... 117(kvm),118(libvirt)
```

(the actual numbers may be different).  If not, then add yourself to these
groups:

```
sudo usermod -a -G kvm,libvirt nsrc
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
  <ip family='ipv6' address='fe80::1' prefix='64'>
  </ip>
  <route address='100.64.0.0' prefix='10' gateway='192.168.122.254'/>
  <route family='ipv6' address='2001:db8::' prefix='32' gateway='fe80::254'/>
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
sudo mv 50-cloud-init.yaml 50-cloud-init.yaml.disabled
```

If it *is* called `50-cloud-init.yaml` then also run the following command
to prevent it being regenerated:

```
echo "network: {config: disabled}" | sudo tee /etc/cloud/cloud.cfg.d/99-disable-network-config.cfg
```

Create a new file `/etc/netplan/10-wan.yaml`.  Include a configuration for
your new WAN interface, with DHCP enabled, and `optional: true` so that
booting is not delayed if it's not plugged in.

When you've finished, it should look like this, but with your WAN
interface name in place of `enx086d41e68ba8`:

```
network:
  version: 2
  ethernets:
    enx086d41e68ba8:
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
  iptables -I FORWARD -j ACCEPT -s 100.64.0.0/10 -i virbr0
  iptables -I FORWARD -j ACCEPT -d 100.64.0.0/10 -o virbr0 -m conntrack --ctstate RELATED,ESTABLISHED
  iptables -t nat -I POSTROUTING -j RETURN -o virbr0
  iptables -t nat -A POSTROUTING -j MASQUERADE -s 100.64.0.0/10
  ip6tables -I FORWARD -j ACCEPT -i virbr0
  ip6tables -I FORWARD -j ACCEPT -o virbr0 -m conntrack --ctstate RELATED,ESTABLISHED
  ip6tables -t nat -I POSTROUTING -j RETURN -o virbr0
  ip6tables -t nat -A POSTROUTING -j MASQUERADE -s 2001:db8::/32
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

Newer kernels (5.0+) apparently don't have this problem, in which case it
may be safe to comment out the ethtool line for a small performance improvement.

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
