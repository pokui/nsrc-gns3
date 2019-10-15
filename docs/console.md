You will need to give students a way to access the consoles on their virtual
routers and switches.

GNS3 provides this by means of telnet on different ports.  It works well,
even allowing multiple sessions to connect to the same port.  Unfortunately,
the port numbers are dynamic, and change each time you start the topology.

The solutions for this are under development and likely to change.

# shellinabox

"shellinabox" allows terminal sessions to take place inside a web browser. 
Install the package:

```
sudo apt-get install shellinabox
```

We have written a front-end which dynamically queries the GNS3 API for the
ports.  Download it and install it:

```
wget https://raw.githubusercontent.com/nsrc-org/nsrc-gns3/master/gns3-shellinabox.py
chmod +x gns3-shellinabox.py
sudo mv gns3-shellinabox.py /usr/local/bin/gns3-shellinabox.py
```

If you have GNS3 http authentication turned on, you will need to edit this
file to set the username and password.

Edit `/etc/default/shellinabox` and change the SHELLINABOX_ARGS setting:

```
SHELLINABOX_ARGS="--no-beep -t -s /:shellinabox:shellinabox:/var/tmp:/usr/local/bin/gns3-shellinabox.py"
```

Now start it:

```
sudo systemctl start shellinabox
sudo systemctl enable shellinabox
```

Point your web browser at <http://192.168.122.1:4200/> to test.  If the
emulator is running, it should show clickable URLs for each of the console
ports.  Click on one to connect, then hit Enter to wake up the serial port.
