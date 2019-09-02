all: iso snapshots

.PHONY: apt-depends
apt-depends:
	sudo apt-get install -y cloud-image-utils yamllint zip unzip

.PHONY: import-cndo
import-cndo:
	scripts/import-project.sh cndo

.PHONY: snapshots
snapshots:
	scripts/make-snapshots.py

iso: scripts/cloud-init-iso.sh
	git rm -f iso/srv1-campus*-init-????????????.iso || rm iso/srv1-campus*-init-????????????.iso || true
	mkdir -p iso
	scripts/cloud-init-iso.sh
