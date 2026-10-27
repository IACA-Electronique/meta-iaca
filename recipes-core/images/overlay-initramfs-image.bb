DESCRIPTION = "Overlay initramfs image"

LICENSE = "MIT"

# Include core-image-minimal as the base
require recipes-core/images/core-image-minimal.bb

IMAGE_FSTYPES = "cpio.gz"
IMAGE_FEATURES = ""
DISTRO_FEATURES = "overlayfs"

PACKAGE_INSTALL = "\
    base-files \
    base-passwd \
    busybox \
    initramfs-overlay-files \
    ${ROOTFS_BOOTSTRAP_INSTALL} \
"

export IMAGE_BASENAME = "overlay-initramfs-image"