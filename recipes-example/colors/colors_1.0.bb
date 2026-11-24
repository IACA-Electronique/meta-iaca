SUMMARY = "Simple colors application"
SECTION = "examples"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

SRC_URI = "file://colors.c"

INHIBIT_PACKAGE_DEBUG_SPLIT = "1"
INHIBIT_PACKAGE_STRIP = "0"

do_compile() {
    ${CC} ${CFLAGS} ${LDFLAGS} -o ${UNPACKDIR}/colors ${UNPACKDIR}/colors.c
}

do_install() {
    install -d ${D}${bindir}
    install -m 0755 ${UNPACKDIR}/colors ${D}${bindir}
}