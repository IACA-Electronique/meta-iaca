RUST_KERNEL_TOOLCHAIN ?= ""
RUST_KERNEL_BINDGEN_DIR ?= ""

LIBCLANG_PATH ?= "/usr/lib/llvm-18/lib"
export LIBCLANG_PATH
export RUST_KERNEL_TOOLCHAIN

PATH:prepend = "${RUST_KERNEL_WRAPPER_DIR}:${RUST_KERNEL_TOOLCHAIN}/bin:${RUST_KERNEL_BINDGEN_DIR}:"

do_configure[vardeps] += "RUST_KERNEL_TOOLCHAIN RUST_KERNEL_BINDGEN_DIR RUST_KERNEL_WRAPPER_DIR LIBCLANG_PATH"
do_compile[vardeps] += "RUST_KERNEL_TOOLCHAIN RUST_KERNEL_BINDGEN_DIR RUST_KERNEL_WRAPPER_DIR LIBCLANG_PATH"

python () {
    for var in ("RUST_KERNEL_TOOLCHAIN", "RUST_KERNEL_BINDGEN_DIR"):
        if not d.getVar(var):
            bb.fatal("%s must be set in local.conf (see rust-kernel-toolchain.bbclass)" % var)
}

inherit rust-check