SUMMARY = "IACA EXEC - Rust-based system watchdog service"
SECTION = "base"
HOMEPAGE = "https://gitlab.iaca-electronique.com/iaca-os/system/iaca-os-exec"
LICENSE = "GPLv3"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/GPL-3.0-or-later;md5=1c76c4cc354acaac30ed4d5eefea7245"

SRC_URI = " \
    git://gitlab.iaca-electronique.com/iaca-os/system/iaca-os-exec.git;protocol=https;branch=master;tag=${PV} \
"

S = "${WORKDIR}/git/src"

do_install () {
    install -d "${D}/usr/local/iaca/os/exec"
    cp -r ${S}/usr/local/iaca/os/exec/* "${D}/usr/local/iaca/os/exec"
    rm -fr "${D}/usr/local/iaca/os/exec/commands/install"

    install -d ${D}${sbindir}
    ln -s /usr/local/iaca/os/exec/os.sh ${D}${sbindir}/os
}

FILES:${PN} = "${sbindir} /usr/local/iaca/os/exec/*"

RDEPENDS:iaca-os-exec = "bash"