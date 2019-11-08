# Leave project running

If for some reason you exit the GNS3 client or it crashes, you do not want
the classroom virtual network to be terminated.  Under `File > Edit Project`
ensure that "Leave this project running in the background when closing"
is checked.  Do this for each topology you use (CNDO, NMM)

![Edit project](gns3-leave-open.png)

# Locked objects

Devices are "locked" in position, so you can't accidentally move them around
or delete them.  Should you wish to do so, then right-click and "Unlock
Item"

# Configuration management web page

The GNS3 GUI currently does not have a way to restore individual devices
from snapshot, or export/import devices of individual IOSv devices (e.g. for
password recovery)

Until those features are added, we have written a small CGI tool to perform
those functions.  It's important that the CGI runs as the `nsrc` user, in
order to have permissions to change the disk image files, so a little work
is required to make this happen.

First, install the necessary packages:

```
sudo apt-get install python3-guestfs apache2-suexec-pristine unzip
sudo a2enmod cgi suexec userdir
sudo chmod +r /boot/vmlinuz-*
```

Create `/etc/apache2/conf-enabled/usercgi.conf` containing:

```
<Directory "/home/*/public_html/cgi-bin/">
    Options ExecCGI
    SetHandler cgi-script
</Directory>
```

Restart apache:

```
sudo systemctl restart apache2
```

As the `nsrc` user, make the directory and install the script:

```bash
mkdir -p ~/public_html/cgi-bin
cd ~/public_html/cgi-bin
wget https://raw.githubusercontent.com/nsrc-org/nsrc-gns3/master/gns3man
chmod 755 ~/public_html/cgi-bin ~/public_html/cgi-bin/gns3man
```

!!! Note
    `suexec` is fussy about permissions, and will not allow scripts to
    execute if the group-write bit is set on the script or its enclosing
    directory.

The CGI should now be available at <http://192.168.122.1/~nsrc/cgi-bin/gns3man>

!!! Warning
    Whenever you update the kernel, you will need to re-run the command:

    ```
    chmod +r /boot/vmlinuz-*
    ```

    This is because the CGI uses libguestfs to read and write the IOSv
    NVRAM, and this in turn needs to read your kernel to start a temporary
    virtual machine.

# Manual configuration management

For reference, here is how these tasks are implemented manually.

## Reset individual device

To reset an individual device to its vanilla, unconfigured state:

* Right-click on a device
* Select "Stop"
* Select "Show in File Manager"

    ![Show in File Manager](show-in-file-manager.png)

* A dialog box will appear, asking if you want to copy the path to the
  clipboard. Say Yes.

    ![Copy path to clipboard](copy-path-to-clipboard.png)

* Login to your server with ssh, and run the following command:

    `rm <paste>/*.qcow2`

    (for `<paste>` you press whatever button causes the clipboard
    to be pasted into your ssh session)

* Start the device

You are just deleting the qcow2 "differencing" file which contains the
differences between the base image and this device.  A new one is created
automatically.

There is a [feature request](https://github.com/GNS3/gns3-gui/issues/2868)
for a more friendly way to do this - or we could make a script.

## Restore individual device from snapshot

This is rather difficult to do manually, but here's the process anyway and
we'll have to turn it into a script.

* Right-click on a device
* Select "Stop"
* Select "Show in File Manager"
* Paste it somewhere.  It will look something like this:

```
/home/nsrc/GNS3/projects/538fd89a-e9f8-4f1c-bb2c-4988d7e9b29d/project-files/qemu/a1b1bac7-24d3-414c-88dd-09de24bb0204
<-------------------- project path -------------------------> <-------------- node relative path ------------------->
```

```
$ cd <project-path>
$ ls snapshots
# Pick the one you want, e.g. ssh-snmp_101019_165326.gns3project
$ unzip -v snapshots/ssh-snmp_101019_165326.gns3project
```

This shows you the nodes in the snapshot.  Unfortunately they have different
UUIDs than the ones on your system :-(

So now you unpack the 'project.gns3' file within the snapshot, and look for
the node ID of the device you want to retrieve:

```
$ unzip -d /tmp snapshots/ssh-snmp_101019_165326.gns3project project.gns3
$ grep -1 core1-campus1 /tmp/project.gns3
                    "style": "font-family: TypeWriter;font-size: 10.0;font-weight: bold;fill: #000000;fill-opacity: 1.0;",
                    "text": "core1-campus1",
                    "x": -19,
--
                "locked": true,
                "name": "core1-campus1",
                "node_id": "7c894529-2ba3-432f-8fd6-ab7d5b471c3b",
```

Now you need to extract that node, but put it in the right place.

```
$ unzip -j snapshots/ssh-snmp_101019_165326.gns3project -d project-files/qemu/a1b1bac7-24d3-414c-88dd-09de24bb0204 \
                                                           <-------------- node relative path ------------------->
    'project-files/qemu/7c894529-2ba3-432f-8fd6-ab7d5b471c3b/*.qcow2'
                        <------- snapshot node ID  -------->
```

There is a [feature request](https://github.com/GNS3/gns3-gui/issues/2870)
for a more friendly way to do this.

## Password recovery

GNS3 currently does not have a way to
[export and import IOSv/IOSvL2 configs](https://github.com/GNS3/gns3-server/issues/1315).

It can be done manually, using guestfish to extract the nvram file and a
script to convert it to text.  The steps are outlined here - they are the
same for IOSv and IOSvL2.  You will need to install package
`libguestfs-tools`.

* STOP THE DEVICE.  This is important!
* Use "Show in file manager", and cd to the node directory
* Optional: examine the disk image using guestfish

```shell
virt-ls -l -a hda_disk.qcow2 -m /dev/sda1:/ /
```

* Extract and convert nvram file

```shell
virt-cat -a hda_disk.qcow2 -m /dev/sda1:/ /nvram >/tmp/nvram
PYTHONPATH=$(echo /usr/share/gns3/gns3-server/lib/*/site-packages) python3 \
    -m gns3server.compute.iou.utils.iou_export /tmp/nvram /tmp/config /tmp/private
```

This gives you the text config in `/tmp/config`. Edit it, e.g. to
change the password or enable secret.

Now you have to reverse the process to convert back to NVRAM and upload
into the disk image:

```shell
PYTHONPATH=$(echo /usr/share/gns3/gns3-server/lib/*/site-packages) python3 \
    -m gns3server.compute.iou.utils.iou_import -c 512 /tmp/nvram /tmp/config /tmp/private
guestfish -a hda_disk.qcow2 -m /dev/sda1:/ -- upload /tmp/nvram /nvram
```

After this you can start the device again.

# libguestfs error

If you see the following error:

```
libguestfs: error: /usr/bin/supermin exited with error status 1.
```

then this is likely just be a permissions problem which can be fixed by:

```
sudo chmod +r /boot/vmlinuz-*
```

(This has to be re-done each time you upgrade the kernel on your server)
