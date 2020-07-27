#!/usr/bin/python3

# Usage:
#   ./shellinaboxd -t -s '/:nsrc:nsrc:/home/nsrc:/home/nsrc/gns3-shellinabox.py'

import os, re, sys
import urllib.parse as parse

GNS3_CONFIG="/home/nsrc/.config/GNS3/2.2/gns3_server.conf"
CREDS = {
    "host": "127.0.0.1",
    "user": None,
    "password": None,
}

# Read config file to get HTTP credentials
if GNS3_CONFIG:
    with open(GNS3_CONFIG) as f:
        for line in f:
            m = re.match(r'^(user|password)\s*=\s*"?(.*?)"?\s*$', line)
            if m:
                CREDS[m.group(1)] = m.group(2)

GNS3_URL="http://" + CREDS["host"] + ":3080"

# Projects which should not be shown to end users
EXCLUDE_PROJECTS = {
    "NOC",
}

url = parse.urlparse(os.environ["SHELLINABOX_URL"])
q = parse.parse_qs(url.query)

# If we know what port to connect to, just connect to it
if q.get("port"):
    port = int(q["port"][0])
    if port < 1024 or port > 65535:
        raise RuntimeError("Invalid port")
    os.execlp("telnet", "telnet", "-E", CREDS["host"], str(port))

import json
import re
import urllib.request as request

def make_url(**kwargs):
    qs = parse.urlencode(kwargs)
    return parse.urlunparse((url.scheme, url.netloc, url.path, url.params, qs, url.fragment))

def dump_project(project_id):
    # https://gns3-server.readthedocs.io/en/latest/api/v2/controller/node/projectsprojectidnodes.html#get-v2-projects-project-id-nodes
    r = request.urlopen(GNS3_URL+"/v2/projects/%s/nodes" % project_id)
    data = json.load(r)
    data = [d for d in data if d.get("name") and d.get("console") and d.get("status") == "started"]
    if not data:
        print("No running devices")
        return
    data.sort(key=lambda d: d["name"])
    for node in data:
        # The name is not needed, but nice to have displayed in URL bar
        print("%-20s %s" % (node["name"], make_url(port=node["console"],name=node["name"])))

passman = request.HTTPPasswordMgrWithDefaultRealm()
passman.add_password(None, GNS3_URL, CREDS["user"], CREDS["password"])
authhandler = request.HTTPBasicAuthHandler(passman)
opener = request.build_opener(authhandler)
request.install_opener(opener)

# If we know what project we want, list its ports
if q.get("project_id"):
    project_id = q["project_id"][0]
    if re.match(r'[^a-z0-9-]', project_id):
        raise RuntimeError("Invalid project_id")
    print("Select a device:")
    print()
    dump_project(project_id)
    print()
    sys.exit(0)

# Iterate over all running projects
# https://gns3-server.readthedocs.io/en/latest/api/v2/controller/project/projects.html#get-v2-projects
r = request.urlopen(GNS3_URL+"/v2/projects")
data = json.load(r)
projs = [proj for proj in data
         if proj.get("status") == "opened"
         and proj.get("name") not in EXCLUDE_PROJECTS]

if not projs:
    print("No running projects")
    sys.exit(0)

for proj in projs:
    #print("%-20s %s" % (proj["name"], make_url(project_id=proj["project_id"])))
    print(proj["name"])
    print()
    dump_project(proj["project_id"])
    print()
