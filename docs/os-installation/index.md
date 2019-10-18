!!! note
    Some familiarity with Linux and the command line is assumed for the
    rest of this document, including that you can edit a file using an editor of
    your choice (e.g.  `vi` or `nano`).

# Operating system installation

Install Ubuntu Linux 18.04, server edition.

Ubuntu 16.04 *might* work with these instructions, but has not been tested,
and some changes may be required (e.g.  network configuration).  Earlier
versions are unlikely to work and already end-of-life.

Desktop edition will probably work, but since you are likely to be running
"headless" with no keyboard and display attached, the GUI is unlikely to be
of benefit.  It will consume additional resources, which means less RAM
available for the labs.  Furthermore, the GUI comes with NetworkManager by
default, and this may interfere with your network configuration.

Don't use any non-LTS version, e.g. 19.04 or 19.10.  These have very short
support lifetimes and you will need to reinstall them within 9 months.

## Unprivileged user

The installation will require you to create a regular user.  This guide will
assume that the user you create is called "nsrc".

Most of the time, when you're working at the shell, you should work as this
user.  When that's the case, the prompt will end with `$`

```
nsrc@brian-kit:~$ 
```

When you need to do something as root, we'll show the command prefixed with
`sudo`.  If you need to do a whole series of things as root, you can use
`sudo -s` to get a root shell, and `exit` when you no longer need it.

```
$ sudo -s
# apt-get update
# apt-get dist-upgrade
# exit
$ 
```

When you are editing a system file - that is, one which is not under your
`/home` directory - then normally you'll need to do that as root.  So you
will need to do `sudo vi ...` or `sudo nano ...`

## Partitioning

Installing the entire system in one large root partition is OK.  The rest of
this section is if you want to partition it differently.

VM base images will be stored in `/var/lib/GNS3/images`.  They will take
several gigabytes, but will not grow during operation.  However there are
other files in `/var`, including apt-cacher-ng cached packages, which can
grow to several gigabytes, along with log files etc.

The running GNS3 configuration will store state under `/home/nsrc/GNS3`. 
This could grow very large: potentially 6 virtual machines each growing up
to 40GB each.  If you are partitioning the system, make sure that `/home`
gets the lion's share of your available space.

If you are familiar with ZFS, then making a large partition for ZFS, and
`/home` as a ZFS filesystem, would be a good idea.

Putting `/var/lib/lxd` on ZFS allows for zero-copy cloning and snapshotting
of lxd containers.  However, you don't *need* to create any lxd containers
on your host; it's just a useful facility for more advanced users, who may
want to spin up extra lightweight pseudo-virtual-machines on demand.

## Swap space

You need very little swap space - 4GB should be plenty.  If your system ever
goes that far into swap, you have serious problems.  However, allowing a
small amount of inactive memory to migrate into swap can help free up RAM
for more important uses.

# Apply updates

After installation, ensure your system is fully up-to-date:

```
sudo apt-get update
sudo apt-get dist-upgrade
```

There's no need to reboot yet, as you'll need to reboot after configuring
the networking.
