.PHONY: iso
iso: CSRv_boot_config.iso

# This ISO image is used when booting CSR1000v.  It makes it use "config.txt"
# on the boot drive for storing its config, instead of encrypted NVRAM.
# It also imports any existing config.txt
CSRv_boot_config.iso: iosxe_config.txt
	genisoimage -output CSRv_boot_config.iso -joliet -rock iosxe_config.txt

.PHONY: install-iso
install-iso:
	rm /var/lib/GNS3/images/QEMU/CSRv_boot_config.iso*
	cp CSRv_boot_config.iso /var/lib/GNS3/images/QEMU/
	sudo systemctl restart gns3@nsrc
