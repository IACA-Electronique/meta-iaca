#!/bin/sh
# RAUC slot hook, executed on the DEVICE during 'rauc install'.
# $1 is the hook type, e.g. 'slot-post-install'.
echo "$1" > /tmp/toto

case "$1" in
    slot-post-install)
        vcmailbox 0x00038064 4 0 1 > /tmp/toto2 2>&1 || exit 10
        ;;
    *)
        ;;
esac
exit 0
