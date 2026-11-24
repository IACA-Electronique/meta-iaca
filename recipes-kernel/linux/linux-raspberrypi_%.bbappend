FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI += " \
    file://custom-features.cfg \
    file://rust.cfg \
"

inherit rust-kernel-toolchain

# Remap build paths in Rust panic-location strings embedded in vmlinux;
# kernel 6.12 appends KRUSTFLAGS to KBUILD_RUSTFLAGS (Makefile:1044),
# otherwise do_package_qa fails on kernel-vmlinux with [buildpaths].
KRUSTFLAGS = "--remap-path-prefix=${WORKDIR}=${TARGET_DBGSRC_DIR} --remap-path-prefix=${TMPDIR}/work-shared=${TARGET_DBGSRC_DIR}"
EXTRA_OEMAKE:append = " KRUSTFLAGS='${KRUSTFLAGS}'"