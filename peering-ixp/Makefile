GNS3_PROJECT ?= peering-ixp

.PHONY: help
help:
	@echo "make (hosts|nocloud|import|snapshots)"

.PHONY: hosts
hosts: hosts-peering-ixp

hosts-peering-ixp: hosts.sh
	./hosts.sh >hosts-peering-ixp

.PHONY: nocloud
nocloud: nocloud-srv.sh nocloud-rs.sh
	./nocloud-srv.sh
	./nocloud-rs.sh

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
