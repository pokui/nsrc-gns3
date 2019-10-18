#!/bin/bash -eu

# Import a gns3 project file (in same way as a portable project would do)
# and reformat the JSON.
# This makes it store nicely in git and let us see differences.

GNS3FILE="${1}"

if [ ! -f "$GNS3FILE" ]; then
  echo "Missing file: $GNS3FILE"
  exit 1
fi
python3 -m json.tool --sort-keys "$GNS3FILE" >project.gns3
cp "$(dirname "$GNS3FILE")/README.txt" README.txt
