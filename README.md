# NSRC GNS3 Virtual Training Platform

See [docs](docs/) directory for setup and user documentation.

# Rendering documentation website

```
sudo apt-get install python3-pip --no-install-recommends
sudo pip3 install mkdocs
mkdocs build
```

The output is generated in a `site/` directory.

# Renegerating the hosts file

```
cd cndo
make hosts
```

# Regenerating cloud-init (nocloud) images

These are attached to the Linux VMs as second disk, to configure them on
startup with correct static IP addresses, username/password, apt-cacher
proxy config etc.  A separate disk image is create for each instance of the
VM within the topology (since they have different IP addresses).

Change directory into the relevant topology:

```
cd [noc|cndo|nmm]
make nocloud
```

The output images are written to a `nocloud/` subdirectory.

The filename intentionally includes part of the md5sum, to distinguish the
different versions.  Therefore, if you ever change these, you will need to
update the GNS3 topology to reference the new disk images in all the srv1
instances.  This in turn means you will then need to re-import the topology
and regenerate the IOSv snapshots (next two steps in this document).

# Updating topology

After changing the topology or device configurations in GNS3, update the
repo from the running copy:

```
cd [noc|cndo|nmm]
make import
```

(The Makefile assumes that the project is called "NOC", "cndo" or "nmm")

This stores a pretty-printed copy of the JSON file (called `project.gns3`)
which can be examined for diffs.  (All the node IDs and link IDs may change;
this is fine)

This topology file is included in all the generated snapshots, so it's
important that you import the topology *before* generating snapshots.
Otherwise, your topology will be reset to the previous version whenever you
restore from one of the snapshots.

# Regenerating snapshots

GNS3 is currently [unable to import IOSv configs](https://github.com/GNS3/gns3-server/issues/1315).

However, configuration can be restored from snapshots of the VM disk state.

This repo contains scripts to generate snapshots, which take the form of zip
files.

```
cd [cndo|nmm]
make snapshots
```

(Note: NOC doesn't have any snapshots)

Once snapshots are built, copy them into the project, e.g. for cndo:

```
cp cndo/snapshots/* ~/GNS3/projects/<uuid>/snapshots/
```

(Note: the snapshot zipfiles contain the node UUIDs, but these are changed
whenever you import a project.  Therefore you must use the same GNS3 server
as the one that you previously exported the project from)

Restart the backend to pick them up, and then they should be visible in
"Manage Snapshots" in the GUI.

Restore from whichever snapshot you want to be the default, initial
classroom setup.  Then immediately do another export of portable project
(without base images, but *with* snapshots).  This is the final project file
that you publish.

## Images directory location

The scripts assume that your GNS3 `images` directory is
`/var/lib/GNS3/images`, as they create qcow2 difference files which point to
backing files at an absolute directory.

If you have already run GNS3 then move your existing images directory:

```
sudo mkdir /var/lib/GNS3
sudo mv ~/GNS3/images /var/lib/GNS3/
```

Point to the new location by creating the [configuration file](https://docs.gns3.com/1f6uXq05vukccKdMCHhdki5MXFhV8vcwuGwiRvXMQvM0/)
`~/.config/GNS3/2.2/gns3_server.conf` so that it contains:

```
[Server]
images_path = /var/lib/GNS3/images
```

(Or you could instead make a symlink: `ln -s /var/lib/GNS3/images ~/GNS3/images`)

## Guestfish errors

Snapshot generation requires guestfish (`apt-get install libguestfs-tools`)

If you see the following error:

```
libguestfs: error: /usr/bin/supermin exited with error status 1.
```

then this is likely just be a permissions problem which can be fixed by:

```
sudo chmod +r /boot/vmlinuz-*
```
