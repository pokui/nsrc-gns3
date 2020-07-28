
Some additional services are required on the host.

# DNS

DNS for the lab environment is handled by dnsmasq (which also provides the
class DHCP service).

To add the DNS entries needed by the labs, you install a "hosts" file.  DNS
requests matching this file are intercepted by dnsmasq and served locally.

The hosts file we provide depends on the topology you wish to run, e.g.
`hosts-cndo-nmm` or `hosts-peering-ixp`. You can replace your
server's existing `/etc/hosts` entirely with this file, or append it to the
end if there's anything else you want to keep.  The contents are available
to the students and VMs inside the labs, as well as to the host itself.

# apt-cacher-ng

All the student VMs are configured to fetch packages via a proxy on
100.64.0.1:3142 - this speeds up downloads drastically when all the class
are fetching the same packages.  Install it:

```
sudo apt-get install apt-cacher-ng
```

We recommend you edit the configuration file `/etc/apt-cacher-ng/acng.conf`
and uncomment/set the following options:

```
ConnectProto: v4

UseWrap: 1
```

The first of these says that even if your machine has picked up an IPv6
address, use IPv4 for outbound connections to package repositories.  Broken
IPv6 networks have been observed as a source of problems before, so this
avoids them.

The second enables "TCP Wrappers" to configure access controls to your proxy
(so that you can block outside parties from abusing your proxy).

To activate these changes:

```
sudo systemctl restart apt-cacher-ng
```

## Securing apt-cacher-ng

To limit which networks can access your proxy, edit `/etc/hosts.allow`:

```
apt-cacher-ng: 127.0.0.1 10.0.0.0/8 100.64.0.0/10 172.16.0.0/12 192.168.0.0/16 [::1] [2001:db8::]/32
```

and `/etc/hosts.deny`:

```
apt-cacher-ng: ALL
```

!!! Note
    Setting `BindAddress: localhost 100.64.0.1` ought to work too, but is
    not a satisfactory solution because apt-cacher-ng can start before
    libvirt has created the virbr0 network - meaning that it only listens on
    the loopback interface.

## Optional: Fetch via your own proxy

(Otherwise known as "eating your own dogfood")

On your server, create `/etc/apt/apt.conf.d/99proxy` containing:

```
Acquire::http::Proxy "http://127.0.0.1:3142/";
Acquire::https::Proxy "DIRECT";
```

This will make your own server's requests go through its own apt-cacher
proxy, except for https repositories.

Test using `apt-get update`.  Check logs using
`tail /var/log/apt-cacher-ng/apt-cacher.log`

# Optional: netdata

[Netdata](https://github.com/netdata/netdata) lets you monitor the
performance of your platform in real time - CPU usage, RAM usage, disk I/O,
and much more.

![Netdata CPU overview](netdata-cpu.png)

(Screenshot shows CPU load while NMM topology starts up and then settles
down into steady state)

To [install](https://github.com/netdata/netdata/tree/master/packaging/installer#linux-64bit-pre-built-static-binary)
or upgrade it, run the following command:

```
bash <(curl -Ss https://my-netdata.io/kickstart-static64.sh)
```

!!! Note
    No 'sudo' is required - it will sudo itself when required

Netdata is then visible at <http://100.64.0.1:19999/>
