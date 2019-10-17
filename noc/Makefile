.PHONY: help
help:
	@echo "make (nocloud|import)"

.PHONY: nocloud
nocloud: nocloud.sh
	./nocloud.sh

.PHONY: import
import:
	../scripts/import-project.sh ../noc.gns3project

#.PHONY: snapshots
#snapshots:
#	../scripts/make-snapshots.py
