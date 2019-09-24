all: nocloud snapshots

.PHONY: apt-depends
apt-depends:
	sudo apt-get install -y cloud-image-utils yamllint zip unzip

.PHONY: import-cndo
import-cndo:
	scripts/import-project.sh cndo

.PHONY: snapshots
snapshots:
	scripts/make-snapshots.py

nocloud: scripts/gen-nocloud.sh
	scripts/gen-nocloud.sh
