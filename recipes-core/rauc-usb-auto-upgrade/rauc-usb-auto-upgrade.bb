SUMMARY = "RAUC USB Auto Upgrade Daemon - Monitors USB devices for RAUC update bundles"
SECTION = "base"
HOMEPAGE = "https://iaca-electronique.com"
LICENSE = "GPLv3"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/GPL-3.0-or-later;md5=1c76c4cc354acaac30ed4d5eefea7245"

PR = "r0"

# Source files
SRC_URI = " \
    file://rauc-usb-auto-upgrade.sh \
    file://rauc-usb-auto-upgrade.init \
"

# Inherit update-rc.d for init script support
inherit update-rc.d allarch

# Install the monitoring script and init script
S = "${WORKDIR}"

# Configuration for the partition label to look for
# This can be overridden in local.conf or other configuration
RAUC_USB_PLUGIN_PARTITION_LABEL ?= "RAUC_UPDATE"

do_install() {
    # Install monitoring script
    install -d ${D}${sbindir}
    install -m 0755 ${S}/rauc-usb-auto-upgrade.sh ${D}${sbindir}/rauc-usb-auto-upgrade

    # Install init script
    install -d ${D}${sysconfdir}/init.d
    install -m 0755 ${S}/rauc-usb-auto-upgrade.init ${D}${sysconfdir}/init.d/rauc-usb-auto-upgrade

    # Create configuration directory
    install -d ${D}${sysconfdir}/rauc-usb-auto-upgrade
    
    # Create configuration file with default values
    echo 'PARTITION_LABEL="${RAUC_USB_PLUGIN_PARTITION_LABEL}"' > ${D}${sysconfdir}/rauc-usb-auto-upgrade/config
}

INITSCRIPT_NAME = "rauc-usb-auto-upgrade"
INITSCRIPT_PARAMS = "defaults 99"

# Package files
FILES:${PN} = " \
    ${sbindir}/rauc-usb-auto-upgrade \
    ${sysconfdir}/init.d/rauc-usb-auto-upgrade \
    ${sysconfdir}/rauc-usb-auto-upgrade/config \
"

# Runtime dependencies
RDEPENDS:${PN} = " \
    rauc \
    util-linux-blkid \
    util-linux-mount \
    util-linux-umount \
    coreutils \
    bash \
"

# Package description
DESCRIPTION = "Daemon that monitors USB storage devices for RAUC update bundles. \
When a USB device with a FAT partition containing a specific identifier is detected, \
the daemon mounts the partition in read-only mode, searches for a 'last.raucb' file, \
and if found, performs a RAUC update installation to the target slot followed by a poweroff."
