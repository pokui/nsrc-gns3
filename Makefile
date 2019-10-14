all: cndo

.PHONY: apt-depends
apt-depends:
	sudo apt-get install -y cloud-image-utils yamllint zip unzip

.PHONY: cndo
cndo: cndo-snapshots cndo-nocloud

.PHONY: cndo-import
cndo-import:
	scripts/import-project.sh cndo

.PHONY: cndo-snapshots
cndo-snapshots:
	cd cndo && ../scripts/make-snapshots.py

.PHONY: cndo-nocloud
cndo-nocloud: cndo/nocloud.sh
	cd cndo && ./nocloud.sh

.PHONY: nmm
nmm: nmm-snapshots nmm-nocloud

.PHONY: nmm-import
nmm-import:
	scripts/import-project.sh nmm

.PHONY: nmm-snapshots
nmm-snapshots:
	cd nmm && ../scripts/make-snapshots.py

.PHONY: nmm-nocloud
nmm-nocloud: nmm/nocloud.sh
	cd nmm && ./nocloud.sh

.PHONY: noc
noc: noc-nocloud

.PHONY: noc-import
noc-import:
	scripts/import-project.sh noc

#.PHONY: noc-snapshots  # noc topology has no templated configs
#noc-snapshots:
#	cd noc && ../scripts/make-snapshots.py

.PHONY: noc-nocloud
noc-nocloud: noc/nocloud.sh
	cd noc && ./nocloud.sh

