# Network Operations Centre (NOC)

The NOC is the simplest topology, and we recommend you start with this to get
familiar with the platform.

Its purpose is to be able to demonstrate the Network Monitoring and
Management tools to the class, populated with real data.  It can become a
long-term store of monitoring data collected over months and years, giving a
more meaningful collection of data to show than the data the students
themselves collect over a few days.

It's also helpful for you, the instructor, to practice configuring these
tools.

# Topology

NOC consists of a single virtual machine, noc.ws.nsrc.org (100.64.0.250). 
It runs the same VM image as the NMM training course.

![NOC topology](noc.png)

The NAT "cloud" represents the connection to the `virbr0` bridge.

The GNS3 project configures the NOC VM to have 2.5GB RAM.  It should be
possible to run this project on a machine with as little as 4GB.

# Files

You will need the following files:

File | Description
:--- | :----------
`noc-<version>.gns3project` | the GNS3 project
`nsrc-nmm-<version>.qcow2` | the VM image with NMM tools pre-installed (large download: ~2GB)
`noc-hdb-<version>.img` | the cloud-init image which configures username/password and static IP

Note that this topology does *not* use the Cisco IOSv or IOSvL2 images. 
This means that it is completely free to use, and can be freely
shared.

# IP addresses

IP Address      | DNS Name
:-------------- | :---------------------------
100.64.0.250 | noc.ws.nsrc.org
2001:db8::250   | noc.ws.nsrc.org

Note that the NOC's IPv6 default gateway is the TR1/TR2 transit routers in
the teaching topology.  Hence if the teaching topology is down, IPv6
connectivity won't work.

This means that if you want to ssh from the server to the NOC VM, and the
teaching topology is not running, you need to force IPv4:

```
ssh -4 sysadm@noc.ws.nsrc.org
# OR
ssh sysadm@100.64.0.250
```

# Credentials

* ssh login: `sysadm` and `nsrc+ws` (the standard student login).  It's up to
  you whether you wish to keep this or change it.  One the one hand, you
  might want students to be able to login and look around; on the other
  hand, you might want to protect it from being damaged by students.
* nagios login: `nagiosadmin` and `nsrc+ws`
* LibreNMS login: `admin` and `nsrc+ws`
* netbox login: `admin` and `nsrc+ws`
* cacti login: `admin` and `nsrc+ws`.  On older systems (based on Ubuntu
  16.04) it is `admin` and `admin`; it then prompts for password change.
* RT login: `root` and `nsrc+ws`
* mysql root password: `nsrc+ws`
* grafana initial login: `admin` and `admin` (but password change is forced)
* VictoriaMetrics API: `admin` and `password123`

# Configuration

The NMM tools are in an unconfigured state, but there are some scripts you
can run to perform a basic automated setup for the CNDO/NMM topology.

Login to the NOC, using SSH or at the console, and run the following
commands:

```
git clone https://github.com/nsrc-org/nsrc-noc-setup.git
cd nsrc-noc-setup
./run-all
```

It's a good idea to reboot to ensure everything comes up as expected.

Alternatively, you may wish to configure them by hand, following the NMM lab
exercises.  You could:

* Monitor the classroom hardware (access point, switch)
* Monitor external resources (e.g. smokeping DNS test to 8.8.8.8)
* Monitor the labs, e.g. Nagios checks of bdr1 and core1 in each campus, so
  you can visualise how the class is progressing.  Note that you won't be
  able to directly reach the dist and edge switches in CNDO, as they are
  behind NAT.
* Collect configs from transit1-nren and transit2-nren (100.64.0.2 and .3)
  using rancid
* Generate graphs of classroom bandwidth usage - SNMP monitoring of
  100.64.0.1 in LibreNMS
* Collect classroom netflow data in nfsen.  This can be extremely interesting
  to see which students are running torrents!

You should also install a HTML page at `/var/www/html/index.html` which links
to all the tools.  You can use
[this sample](https://raw.githubusercontent.com/nsrc-org/nsrc-noc-setup/main/noc/index.html)
as a base.

## snmpd

To allow your physical host to be monitored by LibreNMS, install
and configure snmpd.

!!! Warning
    Do this on your physical host, not inside the NOC VM

```
sudo apt-get install snmpd
```

Refer to the snmp labs in the NMM workshop for how to configure an SNMPv2c
community string and SNMPv3 authentication.  Ensure that the ACL allows
access from `100.64.0.0/22`.

Then return to the LibreNMS web interface and add "gw.ws.nsrc.org" as a
device.  It will take up to 5 minutes for it to be discovered.

## softflowd

To generate netflow data for traffic going in and out of the class, install
softflowd on your server.

!!! Warning
    Do this on your physical host, not inside the NOC VM

```
sudo apt-get install softflowd
```

Edit `/etc/default/softflowd`

```
INTERFACE="virbr0"

OPTIONS="-n 100.64.0.250:9996 -v 9 -t maxlife=5m"
```

Create `/etc/systemd/system/softflowd.service`

```
[Unit]
Description=softflowd
After=network-online.target
Wants=network-online.target
Conflicts=shutdown.target

[Service]
EnvironmentFile=/etc/default/softflowd
ExecStart=/usr/sbin/softflowd -d -i $INTERFACE $OPTIONS
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
```

Be careful to get uppercase and lowercase exactly correct.

!!! Note
    Although softflowd comes with an init script, we replace it
    with a systemd service which auto-restarts it on failure.
    This is because on bootup, the system tries to start softflowd
    before libvirt has created the virbr0 interface.

Now start softflowd:

```
sudo systemctl daemon-reload
sudo systemctl start softflowd
sudo systemctl enable softflowd
```

Then, login to the NOC VM.  You will need to start nfsen there, just like
the students would have had to:

!!! Warning
    Do the following inside the NOC VM

```
sudo update-rc.d nfsen defaults 20
sudo service nfsen start
```

Data will become visible at <http://noc.ws.nsrc.org/nfsen/nfsen.php>

## node_exporter

To allow the host to be monitored by prometheus, install `node_exporter`.

For the current version, follow the instructions in the `ex-node-exporter.md`
lab exercise.  An older version can be obtained via `apt-get install
prometheus-node-exporter`.

# Auto-start

Since the NOC is a separate topology, you can keep your NOC running even
when you shutdown or wipe your teaching topologies.  This is what allows it
to continue to collect data over the long term.

To make this even more useful, you can arrange that:

* The NOC project is opened automatically whenever the GNS3 server starts
* The NOC VM is started automatically when the NOC project is opened
* The NOC project continues running in the background even when you close
  the GNS3 client

These options are available under `File > Edit Project` in the GNS3 client.

![GNS3 project options](noc-persistence.png)
