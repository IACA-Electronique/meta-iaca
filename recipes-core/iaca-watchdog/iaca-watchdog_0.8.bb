SUMMARY = "IACA Watchdog - Rust-based system watchdog service"
SECTION = "base"
HOMEPAGE = "https://gitlab.iaca-electronique.com/iaca-os/system/iaca-os-watchdog"
LICENSE = "GPLv3"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/GPL-3.0-or-later;md5=1c76c4cc354acaac30ed4d5eefea7245"

# Git repository for the Rust source code
SRC_URI = " \
    git://gitlab.iaca-electronique.com/iaca-os/system/iaca-os-watchdog.git;protocol=https;branch=master;tag=${PV} \
    file://iaca-os-watchdog.sysvinit \
"

# Inherit cargo classes for Rust build support
inherit cargo cargo-update-recipe-crates update-rc.d

require ${BPN}-crates.inc

S = "${WORKDIR}/git"

INITSCRIPT_NAME = "${@bb.utils.contains('INIT_MANAGER', 'sysvinit', 'iaca-os-watchdog', '', d)}"
INITSCRIPT_PARAMS = "${@bb.utils.contains('INIT_MANAGER', 'sysvinit', 'defaults', '', d)}"

# Enable Rust binary to be built in release mode
CARGO_BUILD_FLAGS:append = " -Znext-lockfile-bump"

do_install () {
    # Install binary
    install -d ${D}${sbindir}
    install -m 0755 ${B}/target/${CARGO_TARGET_SUBDIR}/iaca-os-watchdog "${D}${sbindir}/${BNP}"

    # Install SysVinit service script only if INIT_MANAGER is sysvinit
    if [ -n "${INITSCRIPT_NAME}" ]; then
        install -d ${D}${sysconfdir}/init.d
        install -m 0755 ${WORKDIR}/iaca-os-watchdog.sysvinit "${D}${sysconfdir}/init.d/iaca-os-watchdog"
    fi
}

# Prevent objcopy from trying to split debug symbols on Rust binaries
INHIBIT_PACKAGE_DEBUG_SPLIT = "1"
INHIBIT_PACKAGE_STRIP = "1"

FILES:${PN} = "${sbindir}/iaca-os-watchdog ${@bb.utils.contains('INIT_MANAGER', 'sysvinit', '${sysconfdir}/init.d/iaca-os-watchdog', '', d)}"