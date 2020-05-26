#!/usr/bin/python3

# Iterate over all template directories.
# Rebuild each snapshot if any of its templates have been updated.
# Do the builds concurrently, up to MAX_JOBS in parallel.

import os, glob, datetime, subprocess, sys

MAX_JOBS = 25

label = datetime.datetime.utcnow().strftime("%d%m%y_%H%M%S")
os.makedirs("snapshots", exist_ok=True)
final_rc = 0

jobs = []
for config in os.listdir("templates"):
    templates = glob.glob("templates/%s/gen-*X" % config)
    if not templates:
        continue
    snaps = glob.glob("snapshots/%s_*.gns3project" % config)
    # Delete old snapshots
    for snap in snaps:
        os.unlink(snap)
    # Generate new snapshot
    if len(jobs) >= MAX_JOBS:
        rc = jobs.pop(0).wait()
        if rc != 0:
            print("ERROR: %r: %r" % (rc, job))
            final_rc = final_rc or rc
    print("Generating %s" % config, file=sys.stderr)
    jobs.append(subprocess.Popen(["../scripts/gen-snapshot.py", config, label]))

for job in jobs:
    rc = job.wait()
    if rc != 0:
        print("ERROR: %r: %r" % (rc, job))
        final_rc = final_rc or rc

sys.exit(final_rc)
