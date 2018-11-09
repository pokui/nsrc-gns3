# NSRC Virtual Training Platform - GNS3 configurations

Download the `project-cndo` directory as a zipfile and change the extension
to `.gns3project`.  This is a "portable project" which you should be able to
import into another GNS3 server.

# Images required

## IOSv

The following IOSv images need to be uploaded separately:

* `vios-adventerprisek9-m.vmdk.SPA.156-2.T` (md5sum: 4e94f3e63ad2771e5662f614921c8c62)
* `3017a0ae-c895-432b-9611-1325ef7828e3` (IOSvL2 15.2.4063, md5sum: c9d556c75a3aa510443014c5dea3dbdb)

## Ubuntu Cloud

For the time being, this topology uses the vanilla
[ubuntu-cloud GNS3 appliance](https://raw.githubusercontent.com/GNS3/gns3-registry/master/appliances/ubuntu-cloud.gns3a)

## Cloud-init ISO images

The [iso/](iso) directory contains the ISO images which are attached to the
CD-ROM drive on `srv1-campus{1..6}` when they boot up.  This assigns the
correct static IP address, creates the `sysadm` account, and configures
use of apt-cacher on 192.168.122.1.
