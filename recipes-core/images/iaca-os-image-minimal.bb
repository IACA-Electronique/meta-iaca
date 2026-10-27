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
IMAGE_INSTALL:append = " bash raspi-utils util-linux hello-rust colors i2c-tools"
IMAGE_INSTALL:append = " iaca-watchdog iaca-os-exec iaca-os-infos iaca-os-infos-daemon"
IMAGE_DEPENDS:append = " overlay-initramfs-image"

# Machine-specific IMAGE_CLASSES and IMAGE_FSTYPES.
# Must be parse-time assignments: image.bbclass consumes IMAGE_CLASSES via
# "inherit_defer" and reads IMAGE_FSTYPES/IMAGE_TYPEDEP:* in its own anonymous
# python block -- both before any python __anonymous() in this recipe runs.
IMAGE_CLASSES:append = " \
    ${@' sdcard_image-rpi image_types_iaca image_types_dir_generic' if (d.getVar('MACHINE') or '').startswith('raspberry') else ''} \
    ${@' image_types_dir_generic image_types_iaca' if (d.getVar('MACHINE') or '').startswith('bananapi') else ''} \
"
IMAGE_FSTYPES = " \
    ${@'rpi-sdimg tar.gz dir_generic iaca' if (d.getVar('MACHINE') or '').startswith('raspberry') else ''} \
    ${@'tar.gz dir_generic iaca' if (d.getVar('MACHINE') or '').startswith('bananapi') else ''} \
"
# Boot files for dir_generic image type — names of files present in
# ${IMGDEPLOYDIR} that are collected into boot.tar.gz by the bbclass.
# IMAGE_BOOT_FILES is defined by the machine config (e.g. uImage, boot.scr,
# dtb for sunxi) and matches the files deployed by kernel and bootloader.
IMAGE_DIR_GENERIC_BOOT_FILES = "${IMAGE_BOOT_FILES}"

# Filesystem configuration
BOOT_SPACE = "128000"
IMAGE_ROOTFS_SIZE = "1048576"
IMAGE_ROOTFS_EXTRA_SPACE = "1048576"

PACKAGE_CLASSES ?= "package_deb"

COMPATIBLE_MACHINE = "raspberrypi5|raspberrypi4|bananapi*"

