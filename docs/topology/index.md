Each of the different lab topologies is built as a GNS3 project.  To load a
project, you import the `.gns3project` file and any related images it needs.

# Importing disk images

If a project references a disk image which hasn't already been imported, it
will fail - the error message will report the name of one of the missing
images.

Unfortunately, importing a project does not yet
[prompt you](https://github.com/GNS3/gns3-gui/issues/2881) to upload the
image files.

For now, you can upload them directly on the server, by copying the file
directly into the `/var/lib/GNS3/images/QEMU/` directory. e.g.

```
cd /var/lib/GNS3/images/QEMU
wget shell.nsrc.org/~vtp/gns3/cndo/ubuntu-16.04-server-cloudimg-amd64-disk1-20191002.1.img
```

Then re-import the project.  If other image files are missing, repeat as
required.

!!! Warning
    You must import the *exact* version of every image, with the correct
    md5sum.  This is because the snapshots are based on these images, and
    the images must be block-for-block identical to what was used at the
    time the project was saved.

!!! Note
    You may end up with multiple projects because of the failed ones -
    e.g. `nmm`, `nmm-1`, `nmm-2` etc.  You can delete the old ones by going
    to `File > Open Project` and selecting each of the previous ones and
    clicking Delete.  The final one can be renamed using `File > Edit Project`
