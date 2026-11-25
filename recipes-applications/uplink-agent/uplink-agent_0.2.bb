SUMMARY = "Uplink agent - Remote control"
SECTION = "base"
HOMEPAGE = "https://gitlab.iaca-electronique.com/linux/uplink/uplink-agent"
LICENSE = "GPL-3.0-or-later"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/GPL-3.0-or-later;md5=1c76c4cc354acaac30ed4d5eefea7245"

# Git repository for the Rust source code
SRC_URI = " \
    git://gitlab.iaca-electronique.com/linux/uplink/uplink-agent.git;protocol=https;branch=dev;tag=${PV}-dev \
    file://run.sh \
    file://config.env \
"

# Inherit cargo classes for Rust build support
inherit cargo cargo-update-recipe-crates

require ${BPN}-crates.inc

# Enable Rust binary to be built in release mode
CARGO_BUILD_FLAGS:append = " -Znext-lockfile-bump"

do_install () {
    install -d ${D}${sbindir}
    install -m 0755 ${UNPACKDIR}/run.sh "${D}${sbindir}/${BPN}"

    install -d ${D}${datadir}/${BPN}
    install -m 0644 ${UNPACKDIR}/config.env "${D}${datadir}/${BPN}/.env"
    install -m 0755 ${B}/target/${CARGO_TARGET_SUBDIR}/uplink-agent "${D}${datadir}/${BPN}/uplink-agent"
}

# Prevent objcopy from trying to split debug symbols on Rust binaries
INHIBIT_PACKAGE_DEBUG_SPLIT = "1"
INHIBIT_PACKAGE_STRIP = "1"

FILES:${PN} = "${sbindir}/${BPN} ${datadir}/${BPN} ${datadir}/${BPN}/*"