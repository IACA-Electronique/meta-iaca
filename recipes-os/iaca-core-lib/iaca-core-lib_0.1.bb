SUMMARY = "IACA CORE LIB - Rust-based library for IACA OS low level functions"
SECTION = "base"
HOMEPAGE = "https://gitlab.iaca-electronique.com/iaca-os/iaca-core-lib"
LICENSE = "GPLv3"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/GPL-3.0-or-later;md5=1c76c4cc354acaac30ed4d5eefea7245"

SRC_URI = " \
    git://gitlab.iaca-electronique.com/iaca-os/iaca-core-lib.git;protocol=https;branch=master;tag=${PV} \
"

inherit cargo cargo-update-recipe-crates

require ${BPN}-crates_${PV}.inc

S = "${WORKDIR}/git"


# Enable Rust binary to be built in release mode
CARGO_BUILD_FLAGS:append = " -Znext-lockfile-bump"