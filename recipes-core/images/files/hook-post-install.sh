#!/bin/sh
# RAUC slot-post-install hook, executed on the DEVICE during 'rauc install'.
#
# Partition layout on /dev/mmcblk0:
#   p2 = boot partition of slot A (holds cmdline.txt)
#   p3 = boot partition of slot B (holds cmdline.txt)
#   p4 = rootfs of slot A
#   p5 = rootfs of slot B
#
# Job of this hook: after a slot was updated, fix the cmdline.txt of the
# OTHER slot so its 'root=' key still points to its own rootfs partition.
#   - installing slot A -> fix cmdline.txt on p3, root= -> mmcblk0p5
#   - installing slot B -> fix cmdline.txt on p2, root= -> mmcblk0p4
#
# $1 is the hook type, e.g. 'slot-post-install'.
#
# Error codes (incremental, exit code tells which step failed):
#   10 = failed to mount the boot partition
#   11 = failed to fix cmdline.txt root= (mount/sed/umount chain)
#   12 = vcmailbox signalling failed
#   13 = failed to set rauc.slot= in cmdline.txt

# **********************************************************************************************************************


get_booted_slot() {
    tr ' ' '\n' < /proc/cmdline | sed -n 's/^rauc\.slot=//p'
}

set_cmdline_root() {
    dev="$1"
    new_root="$2"
    mnt="/tmp/cmdline-mnt"

    mkdir -p "$mnt"
    mount "$dev" "$mnt" || return 10

    sed -i "s|root=[^ ]*|root=$new_root|" "$mnt/cmdline.txt"

    umount "$mnt"
    rmdir "$mnt"
}

set_cmdline_slot() {
    dev="$1"
    slot="$2"
    mnt="/tmp/cmdline-mnt"

    mkdir -p "$mnt"
    mount "$dev" "$mnt" || return 10

    if grep -q "rauc.slot=" "$mnt/cmdline.txt"; then
        sed -i "s|rauc\.slot=[^ ]*|rauc.slot=$slot|" "$mnt/cmdline.txt"
    else
        sed -i "s|$| rauc.slot=$slot|" "$mnt/cmdline.txt"
    fi

    umount "$mnt"
    rmdir "$mnt"
}

signal_install_done() {
    vcmailbox 0x00038064 4 0 1
}

# --------------------------------------------- [ MAIN ] ---------------------------------------------------------------

case "$1" in
    slot-post-install)
        slot=$(get_booted_slot)

        if [ "$slot" = "a" ]; then
            set_cmdline_root /dev/mmcblk0p3 /dev/mmcblk0p5 || exit 11
            set_cmdline_slot /dev/mmcblk0p3 b || exit 13
        elif [ "$slot" = "b" ]; then
            set_cmdline_root /dev/mmcblk0p2 /dev/mmcblk0p4 || exit 11
            set_cmdline_slot /dev/mmcblk0p4 a || exit 13
        fi

        signal_install_done || exit 12
        ;;
    *)
        ;;
esac

exit 0
