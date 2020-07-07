#!/usr/bin/python3

# Usage:
#   ./shellinaboxd -t -s '/ssh:nsrc:nsrc:/home/nsrc:PYTHONIOENCODING=utf-8:replace /home/nsrc/gns3-ssh.py'

import os, sys
import urllib.parse as parse

HOSTS = [
    "oob.srv1.campus1.ws.nsrc.org",
    "oob.srv1.campus2.ws.nsrc.org",
    "oob.srv1.campus3.ws.nsrc.org",
    "oob.srv1.campus4.ws.nsrc.org",
    "oob.srv1.campus5.ws.nsrc.org",
    "oob.srv1.campus6.ws.nsrc.org",
    "noc.ws.nsrc.org",
]
DEFAULT_USER = "sysadm"

# Disable SSH host key checking:
# https://superuser.com/questions/141344/dont-add-hostkey-to-known-hosts-for-ssh
SSH_OPTIONS = [
    "-o", "StrictHostKeyChecking=no",
    "-o", "UserKnownHostsFile=/dev/null",
    "-o", "LogLevel=ERROR",
]
    
url = parse.urlparse(os.environ.get("SHELLINABOX_URL",""))
q = parse.parse_qs(url.query)

# If we know what port to connect to, just connect to it
if q.get("host"):
    host = q["host"][0]
    if host not in HOSTS:
        raise RuntimeError("You cannot go there")
    user = q.get("user", [DEFAULT_USER])[0]
    os.execlp("ssh", "ssh", host, "-l", user, *SSH_OPTIONS)

def make_url(**kwargs):
    qs = parse.urlencode(kwargs)
    return parse.urlunparse((url.scheme, url.netloc, url.path, url.params, qs, url.fragment))

print("Where do you want to go today?")
#print("¿Dónde quieres ir hoy?")
print()

max_width = max((len(h) for h in HOSTS))
for host in HOSTS:
    print("%-*s  =>  %s" % (max_width, host, make_url(host=host)))

print()
