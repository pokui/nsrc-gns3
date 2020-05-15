Scripted setup reduces the amount of time required to get the server up and
running.

The script automatically makes a number of changes *without* prompting for
confirmation, so we recommend you only run it on a fresh system where you
don't mind having its state altered.  The script relies on having an
existing working Internet connection so it can download packages.

If you want to do a manual setup instead, follow the instructions in these
pages:

* [OS Configuration](../os-configuration/)
* [Networking](../networking/)
* [Host Tools](../host-tools/)
* [GNS3 Server](../gns3-server/)
* [Console access](../console-access/)
* [GNS3 Management](../gns3-management/)

# Fetch and run script

Login to your server as your normal user (e.g. "nsrc"), fetch the script and
run it:

```
wget https://raw.githubusercontent.com/nsrc-org/nsrc-gns3/master/gns3setup
chmod +x gns3setup
./gns3setup
```

The script uses `sudo` to run commands with root privileges, so will prompt
you for your password as soon as it needs to.

It is safe to abort the script, and it is safe to run it multiple times -
although it may overwrite files which you have manually changed to put them
back how it thinks they should be.

# Selecting network interfaces

The script will list your network interfaces and ask you to choose:

* The LAN interface - where students and class wifi will connect
* The WAN interface - the uplink for external Internet connectivity

If you have a built-in gigabit ethernet NIC then we recommend you choose
that for the LAN.  It will typically have a short name like `eno1`.

If you are using a USB NIC as your second NIC then we recommend you choose
that for the WAN.  It will typically have a long name containing the
MAC address like `enx086d41e68ba8`.

If the script has picked the right interface already then just hit Enter to
accept it.

For more information see [reconfigure external
ports](../networking/#reconfigure-external-ports) in the manual setup
instructions.

# Review and reboot server

The changes, in particular network changes, won't take effect until you
reboot the server.  You may wish to inspect the modified files first.

If your existing Internet uplink is on the LAN port then you'll have to move
it to the WAN port while the machine is rebooting.

# Next steps

Once this is completed, you can skip straight to [GNS3 Client](../gns3-client/).
