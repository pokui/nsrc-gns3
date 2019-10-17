.PHONY: help
help:
	@echo "make (nocloud|import|snapshots)"

.PHONY: nocloud
nocloud: nocloud.sh
	./nocloud.sh

.PHONY: import
import:
	../scripts/import-project.sh ../nmm.gns3project

.PHONY: snapshots
snapshots:
	../scripts/make-snapshots.py
