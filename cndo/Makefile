.PHONY: help
help:
	@echo "make (hosts|nocloud|import|snapshots)"

.PHONY: hosts
hosts: default.addnhosts

default.addnhosts: hosts.sh
	./hosts.sh >default.addnhosts

.PHONY: nocloud
nocloud: nocloud.sh
	./nocloud.sh

.PHONY: import
import:
	../scripts/import-project.sh ../cndo.gns3project

.PHONY: snapshots
snapshots:
	../scripts/make-snapshots.py
