DESCRIPTION = "Overlay files for initramfs"
LICENSE = "CLOSED"

SRC_URI = " \
    file://init \
    file://iaca-splash.sh \
    file://overlay.sh\
"

S = "${WORKDIR}"

do_install() {
    install -d ${D}

    install -m 0755 ${WORKDIR}/init ${D}/init
    install -m 0755 ${WORKDIR}/iaca-splash.sh ${D}/iaca-splash.sh
    install -m 0755 ${WORKDIR}/overlay.sh ${D}/overlay.sh

    install -d ${D}/dev
    mknod -m 600 ${D}/dev/console c 5 1
    mknod -m 666 ${D}/dev/null c 1 3
}

FILES:${PN} = "\
    /init \
    /iaca-splash.sh \
    /overlay.sh \
    /dev/console \
    /dev/null \
"