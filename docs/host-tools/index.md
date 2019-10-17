
Some additional services are required on the host.

# apt-cacher-ng

All the student VMs are configured to fetch packages via a proxy on
192.168.122.1:3142 - this speeds up downloads drastically when all the class
are fetching the same packages.  Install it:

```
sudo apt-get install apt-cacher-ng
```

We recommend you edit the configuration file `/etc/apt-cacher-ng/acng.conf`
and uncomment/set the following options:

```
BindAddress: localhost 192.168.122.1

ConnectProto: v4
```

The first of these makes apt-cacher listen only on the internal interface,
so it's not accessible on the WAN side (you don't want outside parties
abusing your proxy).  The second says that even if your machine has picked
up an IPv6 address, use IPv4 for outbound connections to package
repositories.  Broken IPv6 networks have been observed as a source of
problems before, so this avoids them.

To activate:

```
sudo systemctl restart apt-cacher-ng
```

## Optional: TCP wrappers

An alternative, more fine-grained way to secure your proxy is to set

```
UseWrap: 1
```

Then edit `/etc/hosts.allow`

```
apt-cacher-ng: 127.0.0.1 10.0.0.0/8 192.168.0.0/16 [::1] [2001:db8::]/16
```

and `/etc/hosts.deny`

```
apt-cacher-ng: ALL
```

This lets you decide explicitly what IP ranges to allow.

## Optional: Fetch via your own proxy

On your server, create `/etc/apt/apt.conf.d/99proxy` containing:

```
Acquire::http::Proxy "http://192.168.122.1:3142/";
Acquire::https::Proxy "DIRECT";
```

This will make your own server's requests go through its own apt-cacher
proxy, except for https repositories.

Test using `apt-get update`.  Check logs using
`tail /var/log/apt-cacher-ng/apt-cacher.log`

## If required: SSL/TLS passthrough

The student VMs are configured to make all requests via the proxy.  If any
of them try to access repositories with `https` URLs, the proxy will not
permit it.  Note that this will only affect you if you've asked students to
add custom package repositories.

There are various [workarounds](https://blog.packagecloud.io/eng/2015/05/05/using-apt-cacher-ng-with-ssl-tls/#caching-objects):

(1) Permit all SSL/TLS through the proxy

```
PassThroughPattern: .*
```

This allows https connections to pass through the proxy.  However,
packages will *not* be cached.

(2) Permit specific URLs through the proxy
    
Example:

```
PassThroughPattern: ^(packagecloud\.io|packagecloud-repositories\.s3\.dualstack\.us-west-1\.amazonaws\.com|packagecloud-prod\.global\.ssl\.fastly\.net|d28dx6y1hfq314\.cloudfront\.net|download\.docker\.com|packages\.grafana\.com|changelogs\.ubuntu\.com|packages\.fluentbit\.io):443$`
```

Similar, and slightly more secure as you can control which repos can be
reached - but packages are still not cached.

(3) Students configure special-form URLs
    
```
# Instead of: deb https://download.docker.com/linux/ubuntu xenial stable

deb http://HTTPS///download.docker.com/linux/ubuntu xenial stable
```

This should be a better solution, as it allows the packages to be cached.

# Kernel Samepage Merging

When you have many similar VMs running, [Kernel Samepage
Merging](https://www.linux-kvm.org/page/KSM) can save RAM by identifying
identical pages and keeping only one copy.

This feature should be enabled automatically - if you want to check, the
configuration is in `/etc/default/qemu-kvm`

Once you have GNS3 up and running, you can check whether KSM is working by
seeing how many pages are shared:

```
$ cat /sys/kernel/mm/ksm/pages_sharing
53997
```

Multiply by 4 to get an estimate (in KB) of the amount of RAM being saved by
KSM.

# Optional: netdata

[Netdata](https://github.com/netdata/netdata) lets you monitor the
performance of your platform in real time - CPU usage, RAM usage, disk I/O,
and much more.

![Netdata CPU overview](netdata-cpu.png)

(Screenshot shows CPU load while NMM topology starts up and then settles
down into steady state)

To [install](https://github.com/netdata/netdata/tree/master/packaging/installer#linux-64bit-pre-built-static-binary)
or upgrade it, run the following command:

```
bash <(curl -Ss https://my-netdata.io/kickstart-static64.sh)
```

!!!note
    No 'sudo' is required - it will sudo itself when required

Netdata is then visible at <http://192.168.122.1:19999/>
