# Install GNS3 server

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

Create file `/etc/systemd/system/gns3@.service` - note that there is
an `@` in the name.  This allows the service to be run for multiple users.

```
[Unit]
Description=GNS3 network simulator
After=network-online.target
Wants=network-online.target
Conflicts=shutdown.target

[Service]
User=%i
Restart=always
RestartSec=5
ExecStart=/usr/bin/gns3server
LimitNOFILE=16384

[Install]
WantedBy=multi-user.target
```

Start gns3 for the "nsrc" user like this:

```shell
sudo systemctl start gns3@nsrc
sudo systemctl enable gns3@nsrc
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
sudo systemctl stop gns3@nsrc
```

As the "nsrc" user, create configuration file
`/home/nsrc/.config/GNS3/2.2/gns3_server.conf` to tell GNS3 to use
the directory you just made.

```
[Server]
images_path = /var/lib/GNS3/images
auth = True
user = nsrc
password = XXXXXXXX
```

Now restart the server:

```shell
sudo systemctl start gns3@nsrc
```

For reference:

* `images_path` tells GNS3 where to put its hard drive images.  The
  pre-generated snapshots have `/var/lib/GNS3/images/QEMU/xxx.img` as the
  base path coded within them, so we need to put images in the same place.
* `auth`, `user` and `password` configure the GNS3 API to require
  authentication.  This will prevent students from connecting and taking
  over the emulator.  The password in this file is in cleartext, so do not
  use a valuable password.  The GNS3 username and password do not need to
  match your system username and password.

There is more documentation on this file
[here](https://docs.gns3.com/1f6uXq05vukccKdMCHhdki5MXFhV8vcwuGwiRvXMQvM0/index.html)
and [here](https://github.com/GNS3/gns3-server/blob/master/conf/gns3_server.conf).

!!! Warning

    Regardless of authentication settings, serial consoles are accessible
    remotely without any authentication, to anyone who knows or guesses the port
    number.  If this is a concern (e.g.  because your WAN interface is a public
    IP) then you can apply firewall rules, or you can bind GNS3 so that it only
    listens on the internal interface:

    ```
    [Server]
    images_path = /var/lib/GNS3/images
    host = 100.64.0.1
    ... etc
    ```

    However there is a [bug](https://github.com/GNS3/gns3-server/issues/1802) in
    gns3-server (at least 2.2.11) which may prevent network traffic flowing when
    you have this setting.  You will also need to change the TARGET setting
    in `~/public_html/cgi-bin/gns3man`.
