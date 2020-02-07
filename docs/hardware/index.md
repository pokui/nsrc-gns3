The training platform is designed to run directly on the hardware (or "bare
metal"), because it makes heavy use of virtualization.  If you were to run
it inside a VM then you would be doing "nested" virtualization - VMs inside
VMs - and it is hard to make this perform acceptably well.

# Specification

The server needs to meet the following minimum specifications:

* Quad-core i7 processor
* 32GB of RAM
* 250GB of SSD
* Gigabit ethernet NIC (ideally two)

Having 64GB RAM and 500GB SSD, or the ability to upgrade to these later, is
desirable.

# Portable devices

If the training kit needs to be portable, we recommend the following
devices:

* [Intel NUC10i7FNH](https://www.intel.com/content/www/us/en/products/boards-kits/nuc/kits/nuc10i7fnh.html)
  (formerly known as "Frost Canyon")
    * Takes one M2 (NVMe) SSD module and/or one 2.5" (SATA) drive.
* [Intel NUC8i7BEH](https://www.intel.com/content/www/us/en/products/boards-kits/nuc/kits/nuc8i7beh.html)
  (formerly known as "Bean Canyon")
    * Takes one M2 (NVMe) SSD module and/or one 2.5" (SATA) drive.
* [Intel NUC6i7KYK](https://www.intel.com/content/www/us/en/products/boards-kits/nuc/kits/nuc6i7kyk.html)
  (formerly known as "Skull Canyon")
    * Older generation but still available
    * Takes two M2 (NVMe) SSD modules, no 2.5" drive
* [Apple Mac Mini 2018](https://www.apple.com/mac-mini/specs/)
    * Available with 4 or 6 cores
    * RAM is upgradable to 64GB
    * On-board SSD is *not* upgradable: best to buy with 500GB for
      future-proofing

The Intel NUCs prior to NUC10 officially only take 32GB RAM, but are widely reported (
[1](https://www.virtuallyghetto.com/2019/03/64gb-memory-on-the-intel-nucs.html),
[2](https://www.reddit.com/r/intelnuc/comments/b99oy7/longterm_experience_with_64_gb_ram_in_skull_canyon/)
) as working with 64GB.  It is possible that you will need to
[upgrade the BIOS](https://kacangisnuts.com/2019/04/yes-intel-nuc-8i5beh-accepts-64-gb-ram/).

If buying an SSD for the Bean Canyon or Frost Canyon then you'll get better performance from
an NVMe module (e.g. Samsung 970 EVO / EVO Pro) than from a SATA drive.

# Second NIC

You will need two ethernet NICs: one for the classroom LAN, and one for the
external uplink.

If only a single NIC is present, then you can use a plug-in network adapter
for the uplink, such as [this one](https://amzn.com/B00YUU3KC6).  We have
tested adapters that use the r8152 chipset.

A USB3 NIC with USB-A connector is the safest option.  A USB-C connected NIC
could be either USB3 or Thunderbolt.  Thunderbolt NICs *should* work, but
the Linux Thunderbolt subsystem might not be as well tested.

A USB2 and/or 100Mbps NIC will work fine too.  Throughput will be less than
a gigabit, but you probably won't be using that much bandwidth on your
uplink anyway.

# Wireless access point

For students to access the network, you will need a wireless access point.

We have found the
[Unifi AP AC Lite](https://www.ui.com/unifi/unifi-ap-ac-lite/) to be
extremely reliable, but other access points may be fine.

# Switch

For a very large class or a permanent installation, you may wish to use two
APs.  In that case, you'll need a switch as well.  A switch also lets you
provide wired connections to students whose wifi adapter is not working
well.

A managed switch is a preferred since it can be used as an SNMP target in
classroom exercises, and if it has PoE outputs then it can power the wifi
access point(s) directly.  A fanless switch is preferred to avoid
distracting noise.

The [Netgear GS110TP](https://www.netgear.com/business/products/switches/smart/GS110TP.aspx#tab-techspecs)
meets all of these requirements.  It is a "Smart Managed Pro" switch,
which includes SNMP and a CLI (telnet to port 60000 - has to be enabled in
the web interface first).

However, beware that some APs need higher power PoE+ (802.3at) rather than
PoE (802.3af), in which case you may need a different model of switch.

Also beware that Netgear "Smart Managed Plus" switches are *not* fully
managed, with only a basic web UI and no SNMP or CLI.

# Accessories

You will need at least three CAT5 cables: wireless access point to power
injector, power injector to server (LAN), server (WAN) to external Internet
connection.

The power supplies for all of the above should be multi-voltage and work in
any country - but check before you travel.  It can be helpful to carry your
own power strip and a universal adapter.

For a permanent classroom installation, UPS power is strongly recommended.
When travelling, ask the host if they can loan you a small UPS.

You'll need a USB flash drive for the OS installation, and it's useful to
carry a few for transferring files.
