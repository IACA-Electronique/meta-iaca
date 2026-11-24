SUMMARY = "Simple helloworld application"
SECTION = "examples"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

SRC_URI = "file://hello.c"

INHIBIT_PACKAGE_DEBUG_SPLIT = "1"
INHIBIT_PACKAGE_STRIP = "0"

do_compile() {
    ${CC} ${CFLAGS} ${LDFLAGS} -o ${UNPACKDIR}/hello ${UNPACKDIR}/hello.c
}

do_install() {
    install -d ${D}${bindir}
    install -m 0755 ${UNPACKDIR}/hello ${D}${bindir}
}