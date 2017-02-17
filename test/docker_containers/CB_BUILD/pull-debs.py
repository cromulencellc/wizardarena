#!/usr/bin/env python
"""Pulls the .deb files necessary to build the CGCBuild container."""

import requests
import os

host = "https://s3.amazonaws.com/www.cromulence.com"

debs = ["binutils-cgc-i386_2.24-9082-cfe-rc4_i386.deb",
        "cgc-service-launcher_9082-cfe-rc4_i386.deb",
        "clang-cgc_3.4-9085-cfe-rc4_i386.deb",
        "libcgcef0_9082-cfe-rc4_i386.deb",
        "cb-testing_9082-cfe-rc4_all.deb",
        "cgc2elf_9082-cfe-rc4_i386.deb",
        "libcgc_9082-cfe-rc4_i386.deb",
        "libpov_9082-cfe-rc4_i386.deb",
        "cgc-sample-challenges_9116-cfe-rc4_i386.deb",
        "cgcef-verify_9082-cfe-rc4_all.deb",
        "libcgcdwarf_9082-cfe-rc4_i386.deb",
        "poll-generator_9082-cfe-rc4_all.deb"]

try:
    os.mkdir("debs")
except:
    pass

print "Downloading deb files..."
for num, debfile in enumerate(debs):
    content = requests.get("{}/debs/{}".format(host, debfile))
    tmpfile = open("debs/{}".format(debfile), "w")
    tmpfile.write(content.content)
    tmpfile.close()
    print "Downloaded {} [{} of {}]".format(debfile, num+1, len(debs))
