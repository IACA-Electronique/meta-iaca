SUMMARY = "Uplink agent - Remote control"
SECTION = "base"
HOMEPAGE = "https://gitlab.iaca-electronique.com/linux/uplink/uplink-agent"
LICENSE = "GPL-3.0-or-later"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/GPL-3.0-or-later;md5=1c76c4cc354acaac30ed4d5eefea7245"

# Service installation is disabled by default.
# Enable it in local.conf with: UPLINK_AGENT_INSTALL_SERVICE = "1"
UPLINK_AGENT_INSTALL_SERVICE ??= "0"

# Git repository for the Rust source code
SRC_URI = " \
    git://gitlab.iaca-electronique.com/linux/uplink/uplink-agent.git;protocol=https;branch=dev;tag=${PV}-dev \
    file://run.sh \
    file://config.env \
    file://uplink-agent.init \
"

# Inherit cargo classes for Rust build support
inherit cargo cargo-update-recipe-crates

# Only inherit update-rc.d when the service is actually enabled, otherwise the
# class generates postinst scripts calling "update-rc.d" with an empty service
# name, which fails at rootfs time.
inherit ${@bb.utils.contains('UPLINK_AGENT_INSTALL_SERVICE', '1', 'update-rc.d', '', d)}

require ${BPN}-crates.inc

# Enable Rust binary to be built in release mode
CARGO_BUILD_FLAGS:append = " -Znext-lockfile-bump"

do_install () {
    install -d ${D}${sbindir}
    install -m 0755 ${UNPACKDIR}/run.sh "${D}${sbindir}/${BPN}"

    install -d ${D}${datadir}/${BPN}
    install -m 0644 ${UNPACKDIR}/config.env "${D}${datadir}/${BPN}/.env"
    install -m 0755 ${B}/target/${CARGO_TARGET_SUBDIR}/uplink-agent "${D}${datadir}/${BPN}/uplink-agent"

    # Install SysVinit service script only if INIT_MANAGER is sysvinit
    # and UPLINK_AGENT_INSTALL_SERVICE is enabled (set "1" in local.conf)
    if [ -n "${INITSCRIPT_NAME}" ]; then
        install -d ${D}${sysconfdir}/init.d
        install -m 0755 ${UNPACKDIR}/uplink-agent.init ${D}${sysconfdir}/init.d/uplink-agent
    fi
}

INITSCRIPT_NAME = "${@bb.utils.contains('INIT_MANAGER', 'sysvinit', bb.utils.contains('UPLINK_AGENT_INSTALL_SERVICE', '1', 'uplink-agent', '', d), '', d)}"
INITSCRIPT_PARAMS = "${@bb.utils.contains('INIT_MANAGER', 'sysvinit', bb.utils.contains('UPLINK_AGENT_INSTALL_SERVICE', '1', 'defaults', '', d), '', d)}"

# Prevent objcopy from trying to split debug symbols on Rust binaries
INHIBIT_PACKAGE_DEBUG_SPLIT = "1"
INHIBIT_PACKAGE_STRIP = "1"

FILES:${PN} = "${sbindir}/${BPN} ${datadir}/${BPN} ${datadir}/${BPN}/* ${@bb.utils.contains('INIT_MANAGER', 'sysvinit', bb.utils.contains('UPLINK_AGENT_INSTALL_SERVICE', '1', '${sysconfdir}/init.d/uplink-agent', '', d), '', d)}"