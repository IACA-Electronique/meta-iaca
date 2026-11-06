#!/bin/sh
# RAUC slot hook, executed on the DEVICE during 'rauc install'.
# $1 is the hook type, e.g. 'slot-post-install'.
case "$1" in
    slot-post-install)
        # Ask the Pi bootloader to try the other boot/rootfs partition once
        # (one-shot tryboot flag in the EEPROM), then reboot into it.
        vcmailbox 0x00038064 4 0 1
        reboot
        ;;
    *)
        ;;
esac
exit 0
