# Install gns3 server

```shell
sudo add-apt-repository ppa:gns3/ppa
sudo apt-get update
sudo apt-get install gns3-server
```

If you are prompted whether non-root users should be allowed to use
ubridge, select "Yes".

Note that GNS3 only works if the front-end and back-end are the same
version.  Therefore we recommend you 'hold' the gns3-server package so
that it is not updated unless you explicitly ask for it:

```shell
sudo apt-mark hold gns3-server
```

You can cancel this later with `apt-mark unhold gns3-server`, e.g. when you
are ready to perform an upgrade.

# Add to ubridge group

Add your unprivileged user into the "ubridge" group:

```shell
sudo usermod -a -G ubridge nsrc
```

# Create a systemd unit file

Create file `/etc/systemd/system/gns3-server@.service` - note that there is
an `@` in the name.  This allows the service to be run for multiple users.

```
[Unit]
Description=GNS3 network simulator
After=network-online.target
Wants=network-online.target
Conflicts=shutdown.target

[Service]
User=%i
Restart=on-failure
RestartSec=5
ExecStart=/usr/bin/gns3server -A

[Install]
WantedBy=multi-user.target
```

Start gns3 for the "nsrc" user like this:

```shell
sudo systemctl start gns3-server@nsrc
sudo systemctl enable gns3-server@nsrc
```

The second line means that it will be automatically started at system boot.

# Create images directory

When virtual machines run in GNS3, they have a fixed backing image and
create a qcow2 ("copy on write") file with the differences.  The filename of
the backing image is stored within this qcow2 file.

Therefore, when we distribute projects which contain snapshots of the
machine state, these snapshots have the path embedded within them.  To make
sure these snapshots are useful, everyone has to use the same path for
backing images - otherwise, images created under `/home/someuser` would not
be usable by someone who uses `/home/otheruser`, say.

To solve this problem, we use an images directory in a fixed location which
all the snapshots reference.  You need to make the same directory:

```
sudo mkdir -p /var/lib/GNS3/images
sudo chown nsrc:nsrc /var/lib/GNS3/images
```

# Adjust GNS3 configuration

Temporarily stop gns3:

```shell
sudo systemctl stop gns3-server@nsrc
```

As the "nsrc" user, create configuration file
`/home/nsrc/.config/GNS3/2.2/gns3_server.conf` to tell GNS3 to use
the directory you just made.

```
[Server]
images_path = /var/lib/GNS3/images
host = 192.168.122.1
auth = True
user = nsrc
password = XXXXXXXX
```

There are some additional, optional settings in here:

* `host = 192.168.122.1` makes GNS3 listen only on the internal interface,
  for security.  If you want to access GNS3 over the Internet on a public
  IP, comment out this line.  Note that even with this setting, the virtual
  serial consoles
  [still bind to all interfaces](https://github.com/GNS3/gns3-server/issues/1667).
  If you are worried about this, then you can use iptables or ufw to
  block inbound connections.
* `auth`, `user` and `password` configure the server to require
  authentication.  This will prevent students from connecting and taking
  over the emulator.  The password in this file is in cleartext, so do not
  use a valuable password.  The GNS3 username and password do not need to
  match your system username and password.

There is more documentation on this file
[here](https://docs.gns3.com/1f6uXq05vukccKdMCHhdki5MXFhV8vcwuGwiRvXMQvM0/index.html).

Now restart the server:

```shell
sudo systemctl start gns3-server@nsrc
```
