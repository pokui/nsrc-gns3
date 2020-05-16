# Install libvirt

Install libvirt:

```
sudo apt-get install libvirt-daemon-system bridge-utils
```

This should install a number of packages as dependencies, including
qemu-kvm.

Now logout and log back in again as the "nsrc" user.  Check that you are in
the "kvm" and "libvirt" groups using the `id` command:

```
nsrc@brian-kit:~$ id
uid=1000(nsrc) gid=1000(nsrc) groups=1000(nsrc), ... 117(kvm),118(libvirt)
```

(the actual numbers may be different).  If not, then add yourself to these
groups:

```
sudo usermod -a -G kvm,libvirt nsrc
```

Logout and login again, and check with `id` again.

# Disable KVM halt polling

Edit or create `/etc/modprobe.d/qemu-system-x86.conf` and add the following
line:

```
options kvm halt_poll_ns=0
```

This disables a KVM
[optimisation](https://www.kernel.org/doc/Documentation/virtual/kvm/halt-polling.txt)
which [seriously affects CSR1000v performance](https://codingpackets.com/blog/kvm-host-high-cpu-fix),
although it doesn't appear to make a noticeable difference on IOSv / IOSvL2.

# Test KVM

Check that your system supports KVM (hardware-accelerated virtualization):

```
sudo kvm-ok
```

If the result says that your CPU does *not* support KVM extensions, then you
need to investigate the problem.  Check your BIOS settings, and ensure that
"VT-x" (Intel) or "AMD-V" is enabled.
