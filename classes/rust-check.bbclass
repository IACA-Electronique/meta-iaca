# Rust toolchain and bindgen version checks

check_rust_toolchain_dirs() {
    if [ ! -d "${RUST_KERNEL_TOOLCHAIN}" ] || [ ! -d "${RUST_KERNEL_BINDGEN_DIR}" ]; then
        bbfatal "ERROR: RUST_KERNEL_TOOLCHAIN or RUST_KERNEL_BINDGEN_DIR directory does not exist; Maybe rust requirement are not installed ?"
    fi
}

check_rustc_version() {
    RUSTC_VERSION=$(${RUST_KERNEL_TOOLCHAIN}/bin/rustc -V | awk '{printf $2}')
    if [ "$(printf '%s\n%s\n' "$RUSTC_VERSION" "1.78.0" | sort -V | tail -n1)" != "$RUSTC_VERSION" ]; then
        bbfatal "ERROR: RUSTC_VERSION $RUSTC_VERSION is less than required 1.78.0"
    fi
}

check_bindgen_version() {
    BINDGEN_VERSION=$(${RUST_KERNEL_BINDGEN_DIR}/bindgen -V | awk '{printf $2}')
    if [ "$(printf '%s\n%s\n' "$BINDGEN_VERSION" "0.65.1" | sort -V | tail -n1)" != "$BINDGEN_VERSION" ]; then
        bbfatal "ERROR: BINDGEN_VERSION $BINDGEN_VERSION is less than required 0.65.1"
    fi
}

do_configure:prepend() {
    check_rust_toolchain_dirs
    check_rustc_version
    check_bindgen_version
}
