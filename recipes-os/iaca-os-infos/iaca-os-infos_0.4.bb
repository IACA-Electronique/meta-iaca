SUMMARY = "IACA INFOS - Bash-based script to manage informations"
SECTION = "base"
HOMEPAGE = "https://gitlab.iaca-electronique.com/iaca-os/system/iaca-os-infos"
LICENSE = "GPLv3"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/GPL-3.0-or-later;md5=1c76c4cc354acaac30ed4d5eefea7245"

SRC_URI = " \
    git://gitlab.iaca-electronique.com/iaca-os/system/iaca-os-infos.git;protocol=https;branch=master;tag=${PV} \
    file://modify-fs-daemon.patch \
"

S = "${WORKDIR}/git/src"

do_install () {
    install -d "${D}/usr/local/iaca/os/exec/commands/infos"
    cp -r ${S}/usr/local/iaca/os/exec/commands/infos/* "${D}/usr/local/iaca/os/exec/commands/infos/"
}

FILES:${PN} = "/usr/local/iaca/os/exec/commands/infos/*"

RDEPENDS:iaca-os-infos = "bash"