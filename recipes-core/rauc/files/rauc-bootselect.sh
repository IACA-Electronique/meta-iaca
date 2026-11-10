#!/bin/sh
# Custom bootloader backend for Raspberry Pi 5
# Implements RAUC custom bootloader handler interface
#
# RAUC calls this handler with the following arguments:
#   get-primary           - Output the current primary slot's bootname to stdout
#   set-primary <bootname> - Set the primary slot to <bootname>
#   get-state <bootname>  - Output "good" or "bad" for <bootname> to stdout
#   set-state <bootname> <state> - Set state for <bootname> (state: good|bad)
#   get-current           - Output the current booted slot's bootname to stdout
#
# Uses VC mailbox interface (0x00038064) to set boot partition
# Raspberry Pi 5 partitions:
#   - Partition 0 (slot a): /dev/mmcblk0p3
#   - Partition 1 (slot b): /dev/mmcblk0p4
#
# Primary slot and slot state (good/bad) are derived from autoboot.txt
# on the boot partition /dev/mmcblk0p1 (mounted only temporarily by this
# script):
#   - slot a good/primary: [all] boot_partition=2, [tryboot] boot_partition=3
#   - slot b good/primary: [all] boot_partition=3, [tryboot] boot_partition=2

set -e

ACTION="$1"
SLOT="$2"
STATE="$3"

# Configuration
AUTOBOOT_PART="/dev/mmcblk0p1"
AUTOBOOT_FILE="autoboot.txt"
AUTOBOOT_MNT="$(mktemp -d /tmp/rauc-autoboot.XXXXXX)"

# Mailbox command components
# Tag 0x00038064 sets the tryboot flag; the last parameter is always 1
MAILBOX_TAG="0x00038064"
REQUEST_SIZE="4"
REQUEST_CODE="0"
TRYBOOT_FLAG="1"

# Map bootname to partition number in autoboot.txt:
# slot a -> 2, slot b -> 3
bootname_to_autoboot_partition() {
    local bootname="$1"
    case "${bootname}" in
        a) echo "2" ;;
        b) echo "3" ;;
        *)
            echo "Error: Invalid bootname '${bootname}'. Must be 'a' or 'b'" >&2
            return 1
            ;;
    esac
}

# Map autoboot.txt partition number to bootname:
# 2 -> slot a, 3 -> slot b
autoboot_partition_to_bootname() {
    local partition="$1"
    case "${partition}" in
        2) echo "a" ;;
        3) echo "b" ;;
        *)
            echo "Error: Invalid autoboot partition '${partition}'" >&2
            return 1
            ;;
    esac
}

# Read boot_partition from the [all] section of an autoboot.txt file
read_autoboot_boot_partition() {
    awk -F= '
        /^\[all\][[:space:]]*$/ { in_all = 1; next }
        /^\[/ { in_all = 0 }
        in_all && $1 ~ /^[[:space:]]*boot_partition[[:space:]]*$/ {
            gsub(/[[:space:]]/, "", $2)
            print $2
            exit
        }
    ' "$1"
}

# Write autoboot.txt so that the given slot is the good (boot) partition
write_autoboot() {
    local slot="$1"
    local file="$2"
    local main_part other_part

    case "${slot}" in
        a) main_part="2"; other_part="3" ;;
        b) main_part="3"; other_part="2" ;;
    esac

    cat > "${file}" <<EOF
[all]
tryboot_a_b=1
boot_partition=${main_part}

[tryboot]
boot_partition=${other_part}
EOF
}

# Map bootname to partition number
# slot a -> partition 0, slot b -> partition 1
bootname_to_partition() {
    local bootname="$1"
    case "${bootname}" in
        a) echo "0" ;;
        b) echo "1" ;;
        *)
            echo "Error: Invalid bootname '${bootname}'. Must be 'a' or 'b'" >&2
            return 1
            ;;
    esac
}

# Map partition number to bootname
partition_to_bootname() {
    local partition="$1"
    case "${partition}" in
        0) echo "a" ;;
        1) echo "b" ;;
        *)
            echo "Error: Invalid partition '${partition}'" >&2
            return 1
            ;;
    esac
}

# Get the current primary slot bootname from the [all] boot_partition
# entry in autoboot.txt on /dev/mmcblk0p1
do_get_primary() {
    local part=""

    if mount "${AUTOBOOT_PART}" "${AUTOBOOT_MNT}" 2>/dev/null; then
        if [ -f "${AUTOBOOT_MNT}/${AUTOBOOT_FILE}" ]; then
            part=$(read_autoboot_boot_partition "${AUTOBOOT_MNT}/${AUTOBOOT_FILE}")
        fi
        umount "${AUTOBOOT_MNT}"
    fi

    case "${part}" in
        2|3)
            autoboot_partition_to_bootname "${part}"
            ;;
        *)
            # Default to slot a if autoboot.txt is missing or unreadable
            echo "a"
            ;;
    esac
}

# Set the primary slot bootname
do_set_primary() {
    local target="$1"
    
    # Set tryboot flag via VC mailbox (last parameter is always 1)
    if command -v vcmailbox >/dev/null 2>&1; then
        if vcmailbox "${MAILBOX_TAG}" "${REQUEST_SIZE}" "${REQUEST_CODE}" "${TRYBOOT_FLAG}" >/dev/null 2>&1; then
            return 0
        else
            echo "Error: vcmailbox command failed" >&2
            return 1
        fi
    else
        echo "Error: vcmailbox utility not found" >&2
        return 1
    fi
}

# Get the boot state for a slot (good or bad) from autoboot.txt on
# /dev/mmcblk0p1: the slot is "good" when [all] boot_partition matches it
do_get_state() {
    local target="$1"
    local expected part=""

    expected=$(bootname_to_autoboot_partition "${target}") || return 1

    if ! mount "${AUTOBOOT_PART}" "${AUTOBOOT_MNT}" 2>/dev/null; then
        # Partition not available: treat slot as not good
        echo "bad"
        return 0
    fi

    if [ -f "${AUTOBOOT_MNT}/${AUTOBOOT_FILE}" ]; then
        part=$(read_autoboot_boot_partition "${AUTOBOOT_MNT}/${AUTOBOOT_FILE}")
    fi
    umount "${AUTOBOOT_MNT}"

    if [ "${part}" = "${expected}" ]; then
        echo "good"
    else
        echo "bad"
    fi
}

# Set the boot state for a slot (good or bad). Marking a slot "good"
# rewrites autoboot.txt on /dev/mmcblk0p1 so that slot becomes the boot
# target; "bad" leaves autoboot.txt unchanged (the other slot stays the
# boot target, so this slot reads back as "bad").
do_set_state() {
    local target="$1"
    local state="$2"

    case "${state}" in
        good|bad)
            ;;
        *)
            echo "Error: Invalid state '${state}'. Must be 'good' or 'bad'" >&2
            return 1
            ;;
    esac

    bootname_to_autoboot_partition "${target}" >/dev/null || return 1

    if [ "${state}" = "bad" ]; then
        return 0
    fi

    if ! mount "${AUTOBOOT_PART}" "${AUTOBOOT_MNT}" 2>/dev/null; then
        echo "Error: Cannot mount ${AUTOBOOT_PART}" >&2
        return 1
    fi

    if ! write_autoboot "${target}" "${AUTOBOOT_MNT}/${AUTOBOOT_FILE}"; then
        umount "${AUTOBOOT_MNT}"
        return 1
    fi
    umount "${AUTOBOOT_MNT}"
}

# Get the current booted slot bootname from /proc/cmdline
do_get_current() {
    if [ -f /proc/cmdline ]; then
        local slot
        slot=$(cat /proc/cmdline | tr ' ' '\n' | grep -E '^rauc\.slot=' | cut -d= -f2)
        
        case "${slot}" in
            a|b)
                echo "${slot}"
                return 0
                ;;
        esac
    fi
    
    # Default to slot a if rauc.slot not found in cmdline
    echo "a"
}

# Main dispatch
case "${ACTION}" in
    get-primary)
        do_get_primary
        ;;
    set-primary)
        if [ -z "${SLOT}" ]; then
            echo "Error: Slot bootname not specified" >&2
            exit 1
        fi
        do_set_primary "${SLOT}"
        ;;
    get-state)
        if [ -z "${SLOT}" ]; then
            echo "Error: Slot bootname not specified" >&2
            exit 1
        fi
        do_get_state "${SLOT}"
        ;;
    set-state)
        if [ -z "${SLOT}" ]; then
            echo "Error: Slot bootname not specified" >&2
            exit 1
        fi
        if [ -z "${STATE}" ]; then
            echo "Error: State not specified" >&2
            exit 1
        fi
        do_set_state "${SLOT}" "${STATE}"
        ;;
    get-current)
        do_get_current
        ;;
    *)
        echo "Usage: $0 {get-primary|set-primary <bootname>|get-state <bootname>|set-state <bootname> <state>|get-current}" >&2
        exit 1
        ;;
esac

exit 0
