#!/bin/bash -eu

# Given a new XXXX.gns3project:
# - remove all the qemu and dynamips differencing files and any snapshots
# - unpack the contents
# - reformat the JSON
# This makes it store nicely in git and let us see differences.

PROJFILE="${1}"

zip -d "$PROJFILE" 'project-files/*' 'snapshots/*' || true
unzip -o "$PROJFILE"
python3 -m json.tool --sort-keys "project.gns3" "project.gns3.new"
mv "project.gns3.new" "project.gns3"
