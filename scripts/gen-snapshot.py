#!/usr/bin/python3

"""
Make a snapshot zip file from a directory of configs.  Working
directory needs to be set to a directory which contains:

* projects.gns3
* README.txt
* templates/<config>/gen-<type>X
* snapshots  # output is written here

It would be much easier if the nvram/config could be stored in
a separate disk, but that doesn't appear to be the case; we have
to make qcow2 differencing files backed by the original image.

NOTE: to get good performance we still need to parallelise the
guestfish filesystem writes.
http://libguestfs.org/guestfs-performance.1.html#parallel-appliances
This is currently done by generating multiple snapshot sets in
parallel by scripts/make-snapshots.py
"""

import json
import os
import re
import shutil
import subprocess
import sys
from zipfile import ZipFile, ZIP_DEFLATED

try:
    from gns3server.compute.iou.utils.iou_import import nvram_import
except ImportError:
    import glob
    sys.path.extend(glob.glob("/usr/share/gns3/gns3-server/lib/*/site-packages"))
    from gns3server.compute.iou.utils.iou_import import nvram_import

config = sys.argv[1]
label = sys.argv[2]
if not config or not label:
    raise RuntimeError("Missing config name or label")

images_dir = "/var/lib/GNS3/images/QEMU"   # sadly we need the absolute path to qcow2 base files
project_file = "project.gns3"
readme_file = "README.txt"
templates_dir = "templates"
zip_file = os.path.join("snapshots", "%s_%s.gns3project" % (config, label))
tmp_dir = "/tmp/gen-snapshot.%d" % os.getpid()

MAPPING = str.maketrans('0123456789','ABCDEFGHIJ')

with open(project_file) as f:
    gns3 = json.load(f)

# Generate all configs
if os.path.exists(tmp_dir):
    shutil.rmtree(tmp_dir)

os.makedirs(tmp_dir)
configs = []
for i, node in enumerate(gns3["topology"]["nodes"]):
    name = node["name"]
    uuid = node["node_id"]
    prop = node["properties"]
    bits = re.split(r'(\d+)', name)
    script = os.path.abspath(os.path.join(templates_dir, config, "gen-%sX" % bits[0]))
    if not os.path.isfile(script):
        print("Skipping: %s" % name)
        continue
    # e.g. edge1-b2-campus3 => [1, 2, 3]
    rc = subprocess.run([script, *bits[1::2]], stdout=subprocess.PIPE, check=True,
            cwd=templates_dir)
    startup = rc.stdout
    # Convert config to nvram format
    nvram = nvram_import(None, startup, None, 512)
    with open(os.path.join(tmp_dir, "%s.config" % name), "wb") as f:
        f.write(startup)
    with open(os.path.join(tmp_dir, "%s.nvram" % name), "wb") as f:
        f.write(nvram)
    label = ("%d" % i).translate(MAPPING)  # can only contain a-zA-Z
    configs.append((name, uuid, prop, label))

# Generate all qcow2 files
gfcmd = [
    "guestfish", "--",
]
for name, uuid, prop, label in configs:
    qcowfile = os.path.join(tmp_dir, "%s.qcow2" % name)
    base = os.path.join(images_dir, prop["hda_disk_image"])
    gfcmd.extend([
        "disk-create", qcowfile, "qcow2", "-1", "backingfile:%s" % base, "compat:1.1", ":",
        "add", qcowfile, "label:%s" % label, ":",
    ])
gfcmd.extend([
    "run", ":",
])
for name, uuid, prop, label in configs:
    gfcmd.extend([
        "mount", "/dev/disk/guestfs/%s1" % label, "/", ":",
        "upload", os.path.join(tmp_dir, "%s.nvram" % name), "/nvram", ":",
        "upload", os.path.join(tmp_dir, "%s.config" % name), "/ios_config.txt", ":",
        "umount", "/", ":",
    ])
subprocess.run(gfcmd, check=True)

with ZipFile(zip_file, "w", ZIP_DEFLATED) as zip:
    # Note: you must include the .gns3 file, otherwise it says
    # "Can't import topology the .gns3 is corrupted or missing"
    zip.write(project_file, "project.gns3")
    zip.write(readme_file, "README.txt")

    for name, uuid, prop, label in configs:
        qcowfile = os.path.join(tmp_dir, "%s.qcow2" % name)
        zip.write(qcowfile, os.path.join("project-files", "qemu", uuid, "hda_disk.qcow2"))

# Tidy up
shutil.rmtree(tmp_dir)
