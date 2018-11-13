#!/usr/bin/python3

# Iterate over all template directories.
# Rebuild each snapshot if any of its templates have been updated.

import os, glob, datetime, subprocess, sys

label = datetime.datetime.utcnow().strftime("%d%m%y_%H%M%S")
os.makedirs("snapshots",exist_ok=True)

for config in os.listdir("templates"):
    templates = glob.glob("templates/%s/gen-*X" % config)
    if not templates:
        continue
    newest_template_ts = 0
    for template in templates:
        ts = os.stat(template).st_mtime
        if newest_template_ts < ts:
            newest_template_ts = ts
    snaps = glob.glob("snapshots/%s_*.gns3project" % config)
    older = [1 for f in snaps if os.stat(f).st_mtime < newest_template_ts]
    # If there is an existing snapshot, and it's not older than the template, then keep it
    if snaps and not older:
        print("Skipping %s" % config, file=sys.stderr)
    # Delete old snapshots
    for snap in snaps:
        rc = subprocess.run(["git", "rm", snap])
        if rc.returncode != 0:
            rc = subprocess.run(["rm", snap])
    # Generate new snapshot
    print("Generating %s" % config, file=sys.stderr)
    subprocess.run(["scripts/gen-snapshot.py", config, label], check=True)
