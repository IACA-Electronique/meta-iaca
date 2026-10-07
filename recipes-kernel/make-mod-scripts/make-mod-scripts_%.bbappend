# Kconfig is evaluated again by "make prepare" in kernel-build-artifacts:
# without rustc/bindgen in PATH, CONFIG_RUST is dropped and rust/ is not built,
# so out-of-tree Rust modules fail with "can't find crate for `core`".

# Filter out GCC-specific flags from HOSTCC/HOSTCXX to prevent them from being
# passed to rustc through the -Clinker= parameter. The kernel's Makefile will
# use KBUILD_HOSTCFLAGS and KBUILD_HOSTLDFLAGS for actual flags.
EXTRA_OEMAKE = " HOSTCC=${BUILD_CC} HOSTCPP=${BUILD_CPP} HOSTCXX=${BUILD_CXX} CROSS_COMPILE=${TARGET_PREFIX}"

inherit rust-kernel-toolchain