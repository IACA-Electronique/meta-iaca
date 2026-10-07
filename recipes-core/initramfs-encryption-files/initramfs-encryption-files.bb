DESCRIPTION = "Custom files for initramfs"
LICENSE = "CLOSED"

SRC_URI = " \
    file://init \
"

S = "${WORKDIR}"

do_install() {
    install -d ${D}

    install -m 0755 ${WORKDIR}/init ${D}/init

    install -d ${D}/dev
    mknod -m 600 ${D}/dev/console c 5 1
    mknod -m 666 ${D}/dev/null c 1 3
}

FILES:${PN} = "\
    /init \
    /dev/console \
    /dev/null \
"