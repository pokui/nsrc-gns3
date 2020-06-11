# Elasticsearch / Logstash / Kibana (ELK)

This is another single-VM topology, containing the OSS (Apache2-licensed)
version of the Elastic Stack, ready to install ElastiFlow for visualization
of Netflow data.

These are heavyweight tools, and it's expected that you'll only run a single
shared instance of them for the whole workshop.  The students can all access
the same web interface for exploring data.

# Topology

This consists of a single virtual machine, elk.ws.nsrc.org
(192.168.122.249).  The VM has been configured with 8GB of RAM.

![ELK topology](elk.png)

# Files

You will need the following files:

File | Description
:--- | :----------
`elk-<version>.gns3project` | the GNS3 project
`nsrc-elk-<version>.qcow2` | the VM image with tools pre-installed (large download: ~1.6GB)
`elk-hdb-<version>.img` | the cloud-init image which configures username/password and static IP

# IP addresses

IP Address      | DNS Name
:-------------- | :---------------------------
192.168.122.249 | elk.ws.nsrc.org, kibana.ws.nsrc.org
2001:db8::249   | elk.ws.nsrc.org, kibana.ws.nsrc.org

# Credentials

* ssh login: `sysadm` and `nsrc+ws` (the standard student login).  It's up
  to you whether you wish to keep this or change it.

* The Kibana dashboard is available at <http://kibana.ws.nsrc.org> (no
  login).  This is a virtualhost, to allow other tools to be added as
  further virtualhosts later if required.

# Software installation

## ElastiFlow

ElastiFlow has a [custom license](http://www.koiossian.com/public/robert_cowart_public_license.txt)
which permits non-commercial use, but forbids redistribution, so it cannot be
supplied in the pre-built VM.

Login to the VM, and then run the following script to download ElastiFlow
and perform all the standard configuration:

```
sudo /usr/local/libexec/elastiflow-setup.sh
```

## Filebeat

Although Filebeat (OSS) is already installed, we provide a setup script for
it as well:

```
sudo /usr/local/libexec/filebeat-setup.sh
```

This sets up the "system" module to read local logs from (`/var/log/syslog`)
and also configures rsyslog to receive UDP port 514, so that you can use it
as a target for logs from other hosts.

# Configuration

ElastiFlow lists on IPv4 UDP port 2055 for Netflow traffic.

If you're running softflowd on the host, then you can change it to send
traffic to Elastiflow instead of nfdump/nfsen by changing
`/etc/default/softflowd` to

```
OPTIONS="-n 192.168.122.249:2055 -v 9 -t maxlife=5m"
```

ElastiFlow does not listen by default on IPv6 addresses, but it can be
[configured](https://github.com/robcowart/elastiflow/blob/master/INSTALL.md#6-configure-inputs)
to do so.

# Disable auto-close

ELK is slow to start up, particularly Logstash: once it's running, you'll
want to keep it running.  Make sure you select "Leave this project running
in the background when closing GNS3" under `File > Edit Project` in the GNS3
client.
