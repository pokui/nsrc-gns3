all: nocloud snapshots

.PHONY: apt-depends
apt-depends:
	sudo apt-get install -y cloud-image-utils yamllint zip unzip

.PHONY: import-cndo
import-cndo:
	scripts/import-project.sh cndo

.PHONY: snapshots
snapshots: snapshots-cndo

.PHONY: snapshots-cndo
snapshots-cndo:
	scripts/make-snapshots.py

.PHONY: nocloud
nocloud: nocloud-cndo

.PHONY: nocloud-cndo
nocloud-cndo: scripts/cndo-nocloud.sh
	scripts/cndo-nocloud.sh
