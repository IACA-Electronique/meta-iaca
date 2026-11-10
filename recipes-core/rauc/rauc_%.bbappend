FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

# See layers/meta-rauc/recipes-core/rauc/rauc-target.inc

# On sysvinit systems, start the RAUC D-Bus service at boot from an init
# script instead of relying on D-Bus service activation: when the activated
# 'rauc service' process exits during startup (config load or slot-state
# determination failure), the bus only reports
# "Launch helper exited with unknown return code 1".
SRC_URI += "file://rauc-service.init"

INITSCRIPT_PACKAGES += "${@bb.utils.contains('DISTRO_FEATURES', 'sysvinit', ' ${PN}-service', '', d)}"
INITSCRIPT_NAME:${PN}-service = "rauc-service"
# Start after dbus (priority 20) and before rauc-mark-good (priority 99),
# which talks to the service over D-Bus.
INITSCRIPT_PARAMS:${PN}-service = "start 98 2 3 4 5 . stop 20 0 1 6 ."

FILES:${PN}-service += "${@bb.utils.contains('DISTRO_FEATURES', 'sysvinit', ' ${sysconfdir}/init.d/rauc-service', '', d)}"

do_install:append() {
    if ${@bb.utils.contains('DISTRO_FEATURES', 'sysvinit', 'true', 'false', d)}; then
        install -d ${D}${sysconfdir}/init.d
        install -m 0755 ${WORKDIR}/rauc-service.init ${D}${sysconfdir}/init.d/rauc-service
    fi
}
