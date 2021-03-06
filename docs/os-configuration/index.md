There are some miscellaneous OS tweaks which are required.

# Disable Spectre/Meltdown mitigations

The platform will be running a large number of virtual machines, and
unfortunately the Spectre/Meltdown mitigations have such a huge impact on
performance that the CPU may be completely swamped.

To disable these mitigations, edit `/etc/default/grub` and set

```
GRUB_CMDLINE_LINUX="mitigations=off"
```

If you are having problems with the text console, adding `nomodeset` here
may help.

You should also set:

```
GRUB_DISABLE_OS_PROBER=true

GRUB_RECORDFAIL_TIMEOUT=2
```

The first is because of [this
bug](https://bugs.debian.org/cgi-bin/bugreport.cgi?bug=788062) which can
cause VM images to be corrupted, if the OS prober finds them.  (This is
unlikely to affect you unless you're using LVM volumes).

The second is helpful for a "headless" system.  There is a feature in Ubuntu
whereby if a boot doesn't complete fully for any reason, then the next boot
hangs indefinitely at the grub menu waiting for a keypress.  We don't want
this to happen when we don't have a keyboard and screen connected.

Once the file is saved, run this command:

```
sudo update-grub
```

# Configure sshd security

When your machine is connected on its WAN side, it may get a public IP
address and be reachable from the Internet.

To prevent attackers making brute-force password attacks against your
system, edit `/etc/ssh/sshd_config` and ensure both these settings are "no":

```
PasswordAuthentication no
...
ChallengeResponseAuthentication no
```

Then add this to the very end of the file:

```
# Allow PasswordAuthentication from trusted networks only
Match Address 100.64.0.0/10,10.0.0.0/8,172.16.0.0/12,192.168.0.0/16,2001:db8::/32,fc00::/7
PasswordAuthentication yes
```

This means you'll be able to use password authentication when connecting on
the local LAN, but access from the Internet will be restricted to
public/private key authentication.

After this change, restart the ssh service:

```
sudo systemctl restart ssh
```

# Disable known hosts hashing (optional)

In its default configuration, the ssh client writes obscured information in
`~/.ssh/known_hosts`.  The idea is to make it harder for an intruder to
learn the names of other hosts you have connected to.

This is not a concern in a lab, so we suggest you edit `/etc/ssh/ssh_config`
and set:

```
HashKnownHosts no
```

This is helpful when reinitializing the lab, as it makes it easier to find
and delete entries from `known_hosts` selectively.

# Disable sudo DNS lookups (optional)

`sudo` can give long timeouts when for some reason DNS is not available.
To disable them, create a file `/etc/sudoers.d/nofqdn` with the
following contents:

```
Defaults !fqdn
```

# Time sync

Check time sync status with:

```
timedatectl status
...
       System clock synchronized: yes
systemd-timesyncd.service active: yes
```

If `systemd-timesyncd.service` is not active then run

```
sudo timedatectl set-ntp on
```

!!! Note
    You may not see `System clock synchronized` change to `yes` for a quite
    a while; this is normal.
