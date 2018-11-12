#!/usr/bin/python3

"""
Make a snapshot zip file from a directory of configs.

TODO: parallelise the guestfish filesystem writes.
http://libguestfs.org/guestfs-performance.1.html#parallel-appliances
Right now it takes about 1 second per guest under Ubuntu 18.04
"""

import json
import os
import re
import subprocess
import sys
from zipfile import ZipFile, ZIP_DEFLATED

try:
    from gns3server.compute.iou.utils.iou_import import nvram_import
except ImportError:
    sys.path.append("/usr/share/gns3/gns3-server/lib/python3.6/site-packages")
    sys.path.append("/usr/share/gns3/gns3-server/lib/python3.5/site-packages")
    from gns3server.compute.iou.utils.iou_import import nvram_import

config = sys.argv[1]
label = sys.argv[2]
if not config or not label:
    raise RuntimeError("Missing config name or label")

images_dir = "/home/nsrc/GNS3/images/QEMU"   # sadly we need the absolute path to qcow2 base files
project_file = "cndo/project.gns3"
templates_dir = os.path.join("templates", config)
zip_file = os.path.join("snapshots", "%s_%s.gns3project" % (config, label))

with open(project_file) as f:
    gns3 = json.load(f)

with ZipFile(zip_file, "w", ZIP_DEFLATED) as zip:
    # Note: you must include the .gns3 file, otherwise it says
    # "Can't import topology the .gns3 is corrupted or missing"
    zip.write(project_file, "project.gns3")

    for node in gns3["topology"]["nodes"]:
        name = node["name"]
        uuid = node["node_id"]
        prop = node["properties"]
        print(name)
        bits = re.split(r'(\d+)', name)
        script = os.path.abspath(os.path.join(templates_dir, "gen-%sX" % bits[0]))
        if not os.path.isfile(script):
            print("Skipping")
            continue
        # e.g. edge1-b2-campus3 => [1, 2, 3]
        rc = subprocess.run([script, *bits[1::2]], stdout=subprocess.PIPE, check=True,
                cwd=templates_dir)
        startup = rc.stdout
        # Convert config to nvram format
        nvram = nvram_import(None, startup, None, 512)
        nvram_file = "/tmp/nvram"  # name must end with /nvram for guestfish to work
        config_file = "/tmp/ios_config.txt"
        with open(nvram_file, "wb") as f:
            f.write(nvram)
        # TEMPORARY FRIG for IOSv routers:
        with open(config_file, "wb") as f:
            f.write(startup)
        # Create empty qcow2 difference file
        base = os.path.join(images_dir, prop["hda_disk_image"])
        qcowfile = "/tmp/hda_disk.qcow2"
        subprocess.run(["qemu-img", "create", "-f", "qcow2", "-b", base, qcowfile], check=True)
        # Add the files to the image
        subprocess.run([
            "guestfish", "--rw", "-a", qcowfile, "-m", "/dev/sda1:/",
            "copy-in", nvram_file, "/", ":",
            "copy-in", config_file, "/",
        ], check=True)
        # Add it to the zip file
        zip.write(qcowfile, os.path.join("project-files", "qemu", uuid, "hda_disk.qcow2"))
        # Clean up
        os.unlink(nvram_file)
        os.unlink(config_file)
