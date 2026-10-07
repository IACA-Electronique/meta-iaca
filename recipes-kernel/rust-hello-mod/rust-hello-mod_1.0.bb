SUMMARY = "Hello world Linux kernel module written in Rust"
SECTION = "kernel"
LICENSE = "GPL-2.0-only"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/GPL-2.0-only;md5=801f80980d171dd6425610833a22dbe6"

SRC_URI = " \
    file://Makefile \
    file://rust_hello.rs \
"

S = "${WORKDIR}"

inherit module rust-kernel-toolchain

# module.bbclass names the package "kernel-module-rust-hello"
RPROVIDES:${PN} += "kernel-module-rust-hello"

# Load the module automatically at boot
KERNEL_MODULE_AUTOLOAD += "rust_hello"
