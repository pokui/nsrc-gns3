.PHONY: help
help:
	@echo "make (nocloud|import)"

.PHONY: nocloud
nocloud: nocloud.sh
	./nocloud.sh

.PHONY: import
import:
	../scripts/import-project.sh ../noc.gns3project
	git diff project.gns3 | grep '^[+-]' | egrep -v '"(node_id|console|link_id)":'

#.PHONY: snapshots
#snapshots:
#	../scripts/make-snapshots.py
