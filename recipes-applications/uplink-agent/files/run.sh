#!/bin/sh

cd /var/lib/uplink

exec uplink-agent

exit $?