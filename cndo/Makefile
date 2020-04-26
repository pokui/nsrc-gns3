GNS3_PROJECT ?= cndo

.PHONY: help
help:
	@echo "make (hosts|nocloud|import|snapshots)"

.PHONY: hosts
hosts: hosts-cndo-nmm

hosts-cndo-nmm: hosts.sh
	./hosts.sh >hosts-cndo-nmm

.PHONY: nocloud
nocloud: nocloud.sh
	./nocloud.sh

.PHONY: import
import:
	../scripts/import-project.sh ~/GNS3/projects/*/$(GNS3_PROJECT).gns3
	git diff project.gns3 | grep '^[+-]' | egrep -v '"(node_id|console|link_id)":'

.PHONY: snapshots
snapshots:
	../scripts/make-snapshots.py

.PHONY: install-snapshots
install-snapshots:
	../scripts/install-snapshots.sh ~/GNS3/projects/*/$(GNS3_PROJECT).gns3
