SUMMARY = "RAUC update bundle for iaca-os-image-minimal"
# CLOSED: the recipe only fetches signing keys and a hook script (no licensed
# sources), which would otherwise trip the license-checksum QA check.
LICENSE = "CLOSED"

FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

inherit bundle

RAUC_BUNDLE_COMPATIBLE = "iaca-os-raspberrypi5"
RAUC_BUNDLE_VERSION ?= "${DISTRO_VERSION}"
RAUC_BUNDLE_SLOTS = "rootfs"

RAUC_SLOT_rootfs = "iaca-os-image-minimal"
RAUC_SLOT_rootfs[fstype] = "ext4"
RAUC_SLOT_rootfs[rename] = "rootfs.ext4"

# Development signing key (NEVER use these in production)
# NOTE: bundle.bbclass runs 'rauc bundle' with cwd=${B}=${WORKDIR}/build, so the
# paths must be absolute (${WORKDIR}) — relative names are resolved against
# ${B} and fopen() fails with "No such file or directory".
RAUC_KEY_FILE ?= "${WORKDIR}/development-1.key.pem"
RAUC_CERT_FILE ?= "${WORKDIR}/development-1.cert.pem"
# Keyring embedded in the bundle for verification chain
RAUC_KEYRING_FILE ?= "${WORKDIR}/ca.cert.pem"

# HOOKS
# The hook executable is registered via [hooks] filename (mandatory when any
# slot uses hooks). The hook itself must be a *slot* hook: in rauc 1.15 the
# bundle-level [hooks] hooks= only supports 'install-check', while
# [image.*] hooks= supports pre-install/install/post-install.
# 'post-install' on the rootfs slot runs as 'slot-post-install' on the device
# after the image has been written to the inactive slot.
RAUC_BUNDLE_HOOKS[file] = "hook-post-install.sh"

RAUC_SLOT_rootfs[hooks] = "post-install"

SRC_URI += "file://${RAUC_KEY_FILE} file://${RAUC_CERT_FILE} file://${RAUC_KEYRING_FILE} file://hook-post-install.sh"