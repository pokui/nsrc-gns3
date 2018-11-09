all: iso

.PHONY: apt-depends
apt-depends:
	sudo apt-get install -y cloud-image-utils yamllint

iso: scripts/cloud-init-iso.sh
	mkdir -p iso
	git rm iso/srv1-campus*-init-????????????.iso || rm iso/srv1-campus*-init-????????????.iso || true
	scripts/cloud-init-iso.sh
