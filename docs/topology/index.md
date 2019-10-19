Each of the different lab topologies is built as a GNS3 project.  To load a
project, you import the `.gns3project` file and any related images it needs.

# Importing disk images

The project will tell you which disk images it needs, if you have not
already imported them.

You must import the *exact* version of every image, with the correct md5sum. 
This is because the snapshots are based on these images, and the images must
be block-for-block identical to what was used at the time the project was
saved.

There are two ways to import images:

1. You can upload them through the GNS3 client.  You will be prompted to
   locate the image file on your laptop, and the client will transfer them
   to the backend over the GNS3 API.

2. You can upload them directly on the server, by copying the file and the
   associated `.md5sum` file directly into the `/var/lib/GNS3/images/QEMU/`
   directory.

The latter approach means you can load files directly onto the server
without going via your laptop: e.g.

```
cd /var/lib/GNS3/images/QEMU
wget shell.nsrc.org/~brian/gns3/images/ubuntu-16.04-server-cloudimg-amd64-disk1-20191002.1.img
wget shell.nsrc.org/~brian/gns3/images/ubuntu-16.04-server-cloudimg-amd64-disk1-20191002.1.img.md5sum
```

However, the files won't be noticed until you restart the GNS3 server, which
is disruptive if you are currently running a topology.

```shell
sudo systemctl restart gns3-server@nsrc
```

# DNS

DNS for the lab environment is handled by dnsmasq (which also provides the
class DHCP service).

To add the DNS entries needed by the labs, you install a "hosts" file.  DNS
requests matching this file are intercepted by dnsmasq and served locally.

The hosts file we provide is called `default.addnhosts`.  You can either
replace your server's existing `/etc/hosts` entirely with this file, or
append it to the end if there's anything else you want to keep.  The
contents are available to the students and VMs inside the labs, as well as
to the host itself.

(dnsmasq also reads a file `/var/lib/libvirt/dnsmasq/default.addnhosts`,
but unfortunately it wipes this back to empty when the server is restarted)

# Addressing plan

Since all the labs use the 192.168.122 network for their external
connectivity, there is a common addressing plan on the backbone.

IP address          | DNS name            | Description
:------------------ | :------------------ | :----------
192.168.122.1       | gw.ws.nsrc.org      | The server itself (gateway to the external Internet)
192.168.122.2-9     |                     | Transit routers
192.168.122.10-19   |                     | Campus 1 out-of-band management
192.168.122.20-29   |                     | Campus 2 out-of-band management
192.168.122.30-39   |                     | Campus 3 out-of-band management
192.168.122.40-49   |                     | Campus 4 out-of-band management
192.168.122.50-59   |                     | Campus 5 out-of-band management
192.168.122.60-69   |                     | Campus 6 out-of-band management
192.168.122.100-249 |                     | DHCP (student laptops)
192.168.122.250     | noc.ws.nsrc.org     | NOC VM
192.168.122.251     | ap1.ws.nsrc.org     | Wireless access point
192.168.122.252     | ap2.ws.nsrc.org     | Wireless access point
192.168.122.253     | sw.ws.nsrc.org      | Switch
192.168.122.254     |                     | Target for inbound static route

Some topologies use the same address space - in particular, CNDO and NMM use
the same backbone addresses for transit routers and out-of-band management. 
This means that if you start both these topologies at the same time, it
won't work.

Inside the labs, address space is taken from 100.64.0.0/10.  This "looks
like" public IP space, but is actually reserved space from
[RFC 6598](https://tools.ietf.org/html/rfc6598).  IPv6 uses 2001:db8::/32,
the documentation prefix.

# Out-of-band management

In the more complex topologies, the student VMs are connected both to the
IOSv/IOSvL2 campus network and the 192.168.122 network.  Their default
gateway points via the virtual campus network, but the 192.168.122
connection functions as an "out-of-band management" network.

When students connect to their VM on its 192.168.122 address, it bypasses
the IOSv network.  This is important because IOSv has a throughput limit of
only 2Mbps (250KB/sec); it also minimises the load on the emulation.

Out-of-band management also means their VMs are accessible even when the
virtual campus network is broken.  This can be useful - for example they can
break the campus network and still get into Nagios to see everything turn
red.

The student machines are configured to fetch packages via 192.168.122.1 as a
proxy (see `/etc/apt/apt.conf.d/99proxy`).  This means that installing
packages is also not throttled by IOSv, and reduces external bandwidth
because of apt-cacher-ng.

# Cloud-init

In some topologies there are multiple small disk images to download.

The reason for this is that the Ubuntu VMs (such as srv1 in the CNDO and NMM
topologies) have two virtual disks attached.

The first is the VM image itself, which can be quite large, but is shared by
all instances of the VM.

The second is a small MSDOS image containing "cloud-init" files.  This is
read when the VM first boots, and is responsible for configuring the VM's
static IP address and creating the default username and password (which are
not hard-coded in the image itself).

If the VM appears multiple times in the same topology, this means a separate
cloud-init image is needed for each instance to come up on the correct IP
address.
