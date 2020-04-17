# Peering-IXP

This is a technical workshop to teach the Interior Gateway Protocol (IGP)
and Border Gateway Protocol (BGP) skills required for configuring
interconnections between the autonomous networks that make up the Internet
according to current industry best practices.

It runs with up to 8 groups.  Each group has:

* A border router (BX)
* A peering router (PX)
* A core router (CX)
* An access router (AX)
* A customer router (CustX)
* A server (srvX)

In addition, there are two "transit" routers which provide the uplinks,
two IXPs, and a route server (Ubuntu/BIRD) at each IXP.

# Files

You will need the following files:

File | Description
:--- | :----------
`peering-ixp-<version>.gns3project` | the GNS3 project
`vios-adventerprisek9-m.vmdk.SPA.157-3.M3` | IOSv image
`vios_l2-adventerprisek9-m.SSA.high_iron_20180619.qcow2` | IOSvL2 image

The total memory allocation of all the devices is 26GB. There should still
be enough RAM to run the NOC on a 32GB machine.

# Backbone addressing plan

IP Address      | DNS Name
:-------------- | :---------------------------
192.168.122.2   | TR1
192.168.122.3   | TR2
192.168.122.5   | RS1
192.168.122.6   | RS2

See the training materials for the addressing plan used inside the network.

# Credentials

The transit routers have username `isplab`, password `nsrc-PW`, enable
`nsrc-EN`.

# Snapshots

There are pre-generated snapshots for many different stages of the lab. 

Normally this class starts with the routers and switches completely
unconfigured.  You can reset to this state using the "00-base" snapshot
(note that the transit routers *are* configured in this snapshot)

You can restore to any given snapshot using `Edit > Manage Snapshots` in the
GNS3 client.  Beware that when you restore from a snapshot it will reset
*all* of the devices - including the Linux servers - and you will also lose
any changes you've made to the network topology itself.
