There are additional services you may wish to run on your host to support
the classroom learning environment.

# Materials webserver

Having the training materials on a local webserver is strongly recommended:
it makes them much faster to download, and means you are not dependent on
functioning Internet.

!!! Note
    We recommend you do this on your physical server (rather than in a VM)
    for simplicity

```shell
sudo apt-get install apache2
sudo chown -R nsrc:nsrc /var/www/html
```

Students can access this webserver at [www.ws.nsrc.org](http://www.ws.nsrc.org/).

Some of the lab exercises ask students to fetch files from
[www.ws.nsrc.org/downloads/](http://www.ws.nsrc.org/downloads/), so in
advance of the class you should create `/var/www/html/downloads/` and copy
the files there.

Otherwise, how you structure this site is up to you.  It can be helpful to
make directories `/workshops/<year>/<workshop-title>` if you teach multiple
workshops.

# Syncthing

[Syncthing](https://syncthing.net) is a robust and secure file
synchronization tool, which you can use to copy web content between your
webserver, your laptop, and/or the central nsrc.org webserver.

To install it on your server, use the [apt package repo](https://apt.syncthing.net):

```
curl -s https://syncthing.net/release-key.txt | sudo apt-key add -
echo "deb https://apt.syncthing.net/ syncthing stable" | sudo tee /etc/apt/sources.list.d/syncthing.list
sudo apt-get update
sudo apt-get install syncthing
```

To enable it for the nsrc user:

```
systemctl start syncthing@nsrc
systemctl enable syncthing@nsrc
```

The syncthing web interface is by default only available on 127.0.0.1
(localhost).  To override this:

```
sudo systemctl edit syncthing@.service
```

Into the editor put:

```
[Service]
ExecStart=
ExecStart=/usr/bin/syncthing -no-browser -no-restart -logflags=0 -gui-address=100.64.0.1:8384
```

Save, and restart:

```
sudo systemctl restart syncthing@nsrc
```

The web interface will then be at <https://100.64.0.1:8384/>.  On first
login you should set a GUI authentication username and password.

Note that every instance of syncthing has a unique cryptographic ID: you can
find yours using `Actions > Show ID` in the web interface.

You can then configure remote devices to share with (each device will need
to paste in the ID of the other) and then configure folders to share.  Since
syncthing is running as user 'nsrc', these folders will also need to be
owned by 'nsrc'.

# Unifi controller

If you are using Unifi access points, the controller software will let you
configure SSID, WPA password etc.  You can also configure the access
point(s) on static IP addresses (100.64.0.251 and .252 are reserved for
this purpose) and enable SNMP.

Having the controller present on the 100.64.0.0 network is the easiest way
to get AP discovery to work.

You can simply run the unifi controller on your laptop - it is available for
Windows, Mac and Linux.

If you want to run it on the server, then we suggest you install it inside
your NOC VM.  Beware that it typically consumes 0.5-1GB of RAM.

To [install](https://help.ubnt.com/hc/en-us/articles/220066768-UniFi-How-to-Install-and-Update-via-APT-on-Debian-or-Ubuntu)
Unifi under Ubuntu 16.04 or 18.04, ssh to noc.ws.nsrc.org and run:

```shell
sudo apt-get update && sudo apt-get install ca-certificates apt-transport-https
echo 'deb http://www.ui.com/downloads/unifi/debian stable ubiquiti' | sudo tee /etc/apt/sources.list.d/100-ubnt-unifi.list
sudo apt-key adv --keyserver keyserver.ubuntu.com --recv 06E85760C0A52C50
# Workarounds for Ubuntu 18.04 only
wget -qO - https://www.mongodb.org/static/pgp/server-3.4.asc | sudo apt-key add -
echo "deb https://repo.mongodb.org/apt/ubuntu xenial/mongodb-org/3.4 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-3.4.list
sudo apt-mark hold "openjdk-11-*"
# end workarounds
sudo apt-get update && sudo apt-get install openjdk-8-jre-headless unifi
```

The workarounds are because the unifi package has not been updated to work
with the newer versions of MongoDB and Java which are packaged with Ubuntu
18.04.  There is a script in
[this thread](https://community.ui.com/questions/UniFi-Installation-Scripts-or-UniFi-Easy-Update-Script-or-UniFi-Lets-Encrypt-or-Ubuntu-16-04-18-04-/ccbc7530-dd61-40a7-82ec-22b17f027776)
which can automate the process.

You should then be able to access it at <https://noc.ws.nsrc.org:8443/>

Alternatively, you could install the Unifi controller directly on your host
(physical server).

Another option is to isolate it inside an lxd container on your host.  This
requires several steps, and the following is only a rough outline:

```shell
sudo lxd init       # to prepare lxd for use
lxc profile copy default virbr0
lxc profile edit virbr0

----
config: {}
description: Connect eth0 to virbr0
devices:
  eth0:
    name: eth0
    nictype: bridged
    parent: virbr0
    type: nic
name: virbr0
----

lxc launch -p virbr0 ubuntu:16.04 unifi
lxc exec unifi bash
... continue with installation of Unifi controller as above
exit
```

The container will get a dynamic (DHCP) 100.64.1-3 address.
