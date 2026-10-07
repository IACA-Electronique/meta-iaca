SUMMARY = "IACA OS Minimal Image"
DESCRIPTION = "Minimal image for IACA OS with essential packages"
LICENSE = "MIT"

# Include core-image-minimal as the base
require recipes-core/images/core-image-minimal.bb


EXTRA_IMAGE_FEATURES += " \
    debug-tweaks \
    package-management \
"

# Package installation
IMAGE_INSTALL:append = " kernel-modules"
IMAGE_INSTALL:append = " bash raspi-utils util-linux hello-rust rust-hello-mod colors i2c-tools"
IMAGE_INSTALL:append = " iaca-watchdog iaca-os-exec iaca-os-infos iaca-os-infos-daemon"


IMAGE_CLASSES += "sdcard_image-rpi image_types_iaca image_types_dir"
IMAGE_FSTYPES = "rpi-sdimg tar.gz dir iaca"

# Filesystem configuration
BOOT_SPACE = "128000"
IMAGE_ROOTFS_SIZE = "1048576"
IMAGE_ROOTFS_EXTRA_SPACE = "1048576"

PACKAGE_CLASSES ?= "package_deb"

COMPATIBLE_MACHINE = "raspberrypi5|raspberrypi4"

