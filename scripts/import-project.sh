#!/bin/bash -eu

# Given a new cndo.gns3project:
# - remove all the qemu and dynamips differencing files
# - unpack the contents
# - reformat the JSON
# This makes it store nicely in git and let us see differences.

PROJECT="${1}"
PROJFILE="$PROJECT.gns3project"

zip -d "$PROJFILE" 'project-files/*' 'snapshots/*' || true
unzip -d "$PROJECT" -o "$PROJFILE"
python3 -m json.tool --sort-keys "$PROJECT/project.gns3" "$PROJECT/project.gns3.new"
mv "$PROJECT/project.gns3.new" "$PROJECT/project.gns3"
