SUMMARY = "IACA INFOS DAEMON - Rust-based daemon to map i2c board manager to filesystem"
SECTION = "base"
HOMEPAGE = "https://gitlab.iaca-electronique.com/iaca-os/tools/iaca-system-infos-daemon"
LICENSE = "GPLv3"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/GPL-3.0-or-later;md5=1c76c4cc354acaac30ed4d5eefea7245"

SRC_URI = " \
    gitsm://gitlab.iaca-electronique.com/iaca-os/tools/iaca-system-infos-daemon.git;protocol=https;nobranch=1;submodules=1;tag=${PV} \
    file://iaca-os-infos-daemon.sysvinit \
"

inherit cargo cargo-update-recipe-crates update-rc.d

require ${BPN}-crates_${PV}.inc

S = "${WORKDIR}/git"

INITSCRIPT_NAME = "${@bb.utils.contains('INIT_MANAGER', 'sysvinit', 'iaca-os-infos-daemon', '', d)}"
INITSCRIPT_PARAMS = "${@bb.utils.contains('INIT_MANAGER', 'sysvinit', 'defaults', '', d)}"

EXECUTABLE_NAME = "${INITSCRIPT_NAME}"

# Enable Rust binary to be built in release mode
CARGO_BUILD_FLAGS:append = " -Znext-lockfile-bump"

do_install () {
    # Install binary
    install -d ${D}${sbindir}
    install -m 0755 ${B}/target/${CARGO_TARGET_SUBDIR}/system-infos-daemon "${D}${sbindir}/${EXECUTABLE_NAME}"

    # Install SysVinit service script only if INIT_MANAGER is sysvinit
    if [ -n "${INITSCRIPT_NAME}" ]; then
        install -d ${D}${sysconfdir}/init.d
        install -m 0755 ${WORKDIR}/iaca-os-infos-daemon.sysvinit "${D}${sysconfdir}/init.d/${INITSCRIPT_NAME}"
    fi
}

FILES:${PN} = "${sbindir}/${EXECUTABLE_NAME} ${@bb.utils.contains('INIT_MANAGER', 'sysvinit', '${sysconfdir}/init.d/${INITSCRIPT_NAME}', '', d)}"