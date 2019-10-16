# Network Monitoring and Management (NMM)

NMM is a trimmed version of the [CNDO](../cndo/) topology.

![NMM topology](nmm-complete.png)

The building edge switches are removed, and instead each srv1 host has 2.5GB
RAM, sufficient to run multiple NMM tools.  The total memory usage is again 27GB.

![NMM campus](nmm-campus.png)

# Files

You will need the following files:

File | Description
:--- | :----------
`nmm-<version>.gns3project` | the GNS3 project
`vios-adventerprisek9-m.vmdk.SPA.157-3.M3` | IOSv image - same as CNDO
`vios_l2-adventerprisek9-m.SSA.high_iron_20180619.qcow2` | IOSvL2 image - same as CNDO
`nsrc-nmm-<version>.qcow2` | the VM image with NMM tools pre-installed - same as NOC
`IOSv_startup_config.img` | empty config disk for IOSv - same as CNDO
`nmm-srv1-campus<N>-hdb-<version>.img` (x 6) | cloud-init configs for srv1 in each campus

# lxd containers

Each srv1 virtual machine starts 6 lxd containers inside it, called
host1-host6.  From the students' point of view, they see 7 virtual machines
in their campus: srv1 and host1-6.

![NMM campus student view](nmm-campus1-detailed.png)

But inside GNS3, there is only srv1.  Stopping this will also stop host1-6.

Each of the "host" containers has a set of the smaller NMM tools
preinstalled:

* nagios
* snmp / snmpd
* smokeping
* rsyslog
* swatch

This means that for exercises using these tools, you have 36 instances to
play with, and each student can work on their own instance.

The top-level VM (srv1) contains the larger and more resource-intensive
tools:

* LibreNMS
* nfsen
* RT
* rancid
* mysql (used by LibreNMS and RT)

This means that for exercises using these tools, students will have to work
in their campus groups.

# Backbone addressing plan

All the containers have out-of-band interfaces, so that students' ssh and
web traffic does not need to traverse the emulated network.

IP Address      | DNS Name
:-------------- | :---------------------------
192.168.122.2   | transit1-nren.ws.nsrc.org
192.168.122.3   | transit2-nren.ws.nsrc.org
192.168.122.10  | srv1-oob.campus1.ws.nsrc.org
192.168.122.11  | host1-oob.campus1.ws.nsrc.org
192.168.122.12  | host2-oob.campus1.ws.nsrc.org
192.168.122.13  | host3-oob.campus1.ws.nsrc.org
192.168.122.14  | host4-oob.campus1.ws.nsrc.org
192.168.122.15  | host5-oob.campus1.ws.nsrc.org
192.168.122.16  | host6-oob.campus1.ws.nsrc.org
192.168.122.2x  | (ditto for campus2)
192.168.122.3x  | (ditto for campus3)
192.168.122.4x  | (ditto for campus4)
192.168.122.5x  | (ditto for campus5)
192.168.122.6x  | (ditto for campus6)
192.168.122.254 | transit-nren.ws.nsrc.org (on transit1-nren)

See the training materials for the addressing plan used inside the network.

# Snapshots

There is a smaller set of snapshots provided.

* `default` is the initial state.  All routing is configured and the devices
  have usernames/passwords set, but ssh is not enabled.
* `ssh` is a snapshot where ssh has been enabled and telnet disabled. Note
  however that you will need to login to each device and do
  `crypto key generate rsa modulus 2048`, as this key is not stored within
  the config.
* `ssh-snmp` is similar, but snmp has also been configured.
* There is no snapshot with netflow configured (yet)

Beware that resetting to any of these snapshots will also reset all srv1 and
host1-6 to their default states - any work that students have done will be
erased!  Therefore you almost certainly only want to do this once, before the
course starts.

# Credentials

The student routers have username `nmmlab`, password `lab-PW`, enable
`lab-EN`.

The transit routers have username `nsrc`, password `lab-PW`, enable
`lab-EN`.

srv1 and host1-6 ssh login is `sysadm` with password `nsrc+ws`.

Monitoring tool credentials are as per the [NOC](../noc/#credentials) topology -
it's the same VM image.

# lxd technical background

The fact that host1-6 are lxd containers is an implementation detail. 
However, if you login to srv1, you can see and manage the containers using
the `lxc` command-line tool:

```
sysadm@srv1:~$ lxc list
+-------------+---------+-----------------------+----------------------------------------+------------+-----------+
|    NAME     |  STATE  |         IPV4          |                  IPV6                  |    TYPE    | SNAPSHOTS |
+-------------+---------+-----------------------+----------------------------------------+------------+-----------+
| gold-master | STOPPED |                       |                                        | PERSISTENT | 0         |
+-------------+---------+-----------------------+----------------------------------------+------------+-----------+
| host-master | STOPPED |                       |                                        | PERSISTENT | 0         |
+-------------+---------+-----------------------+----------------------------------------+------------+-----------+
| host1       | RUNNING | 192.168.122.11 (eth1) | 2001:db8:1:1::131 (eth0)               | PERSISTENT | 0         |
|             |         | 100.68.1.131 (eth0)   | 2001:db8:1:1:216:3eff:fed8:988e (eth0) |            |           |
+-------------+---------+-----------------------+----------------------------------------+------------+-----------+
| host2       | RUNNING | 192.168.122.12 (eth1) | 2001:db8:1:1::132 (eth0)               | PERSISTENT | 0         |
|             |         | 100.68.1.132 (eth0)   | 2001:db8:1:1:216:3eff:fef0:c02a (eth0) |            |           |
+-------------+---------+-----------------------+----------------------------------------+------------+-----------+
| host3       | RUNNING | 192.168.122.13 (eth1) | 2001:db8:1:1::133 (eth0)               | PERSISTENT | 0         |
|             |         | 100.68.1.133 (eth0)   | 2001:db8:1:1:216:3eff:feec:66e (eth0)  |            |           |
+-------------+---------+-----------------------+----------------------------------------+------------+-----------+
| host4       | RUNNING | 192.168.122.14 (eth1) | 2001:db8:1:1::134 (eth0)               | PERSISTENT | 0         |
|             |         | 100.68.1.134 (eth0)   | 2001:db8:1:1:216:3eff:fe7c:8e93 (eth0) |            |           |
+-------------+---------+-----------------------+----------------------------------------+------------+-----------+
| host5       | RUNNING | 192.168.122.15 (eth1) | 2001:db8:1:1::135 (eth0)               | PERSISTENT | 0         |
|             |         | 100.68.1.135 (eth0)   | 2001:db8:1:1:216:3eff:fe33:e459 (eth0) |            |           |
+-------------+---------+-----------------------+----------------------------------------+------------+-----------+
| host6       | RUNNING | 192.168.122.16 (eth1) | 2001:db8:1:1::136 (eth0)               | PERSISTENT | 0         |
|             |         | 100.68.1.136 (eth0)   | 2001:db8:1:1:216:3eff:fe37:687 (eth0)  |            |           |
+-------------+---------+-----------------------+----------------------------------------+------------+-----------+
```

This can be useful.  For example, if a student has broken the password in
one of the hostX containers, you can login to srv1, get a root shell inside
the container, and reset the password.

```
$ lxc exec host1 bash
# passd sysadm
# exit
```

The "gold-master" and "host-master" are pre-built lxd images which are
cloned to create host1-6 when the VM first starts up (controlled by
cloud-init).  You should not start these.

The filesystem in the VM is btrfs.  This allows the host containers to be
launched as zero-copy clones, and also allows de-duplication of blocks
between the VM Ubuntu image and the container Ubuntu image.
