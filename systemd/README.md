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
