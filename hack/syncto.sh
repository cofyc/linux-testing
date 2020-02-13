#!/bin/bash
#
# Use to sync kernel to another machine for testing.
#

IP=192.168.2.144

rsync -a --no-links -e ssh /lib/modules/4.10.0-rc4+/ root@$IP:/lib/modules/4.10.0-rc4+/
