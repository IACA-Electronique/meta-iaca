FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI += " \
    file://custom-features.cfg \
    file://rust.cfg \
"

inherit rust-kernel-toolchain