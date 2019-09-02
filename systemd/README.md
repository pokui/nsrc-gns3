# systemd unit file for gns3server

Install the file [gns3server@.service](gns3server@.service) as `/etc/systemd/system/gns3server@.service`

Run the following commands, assuming you want to run gns3server as the
`nsrc` user:

```
systemctl daemon-reload
systemctl start gns3server@nsrc
systemctl enable gns3server@nsrc
```

gns3server will then be started automatically when the machine boots.

# Access controls

Additional configuration can be made in
`/home/nsrc/.config/GNS3/gns3_server.conf`.  In particular, you can bind to
a local IP if you don't want access to be available from the WAN, and you
can set a username/password to prevent students messing with the GNS3
backend directly.

```
[Server]
;host = 127.0.0.1
images_path = /var/lib/GNS3/images
auth = True
user = nsrc
password = XXXXXXXX
```
