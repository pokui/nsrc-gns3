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

.PHONY: cndo-snaps
cndo-snaps: cndo-snaps.gns3project

cndo-snaps.gns3project: cndo.gns3project cndo/snapshots
	zip -r cndo-snaps.gns3project cndo

iso: scripts/cloud-init-iso.sh
	mkdir -p iso
	git rm iso/srv1-campus*-init-????????????.iso || rm iso/srv1-campus*-init-????????????.iso || true
	scripts/cloud-init-iso.sh
