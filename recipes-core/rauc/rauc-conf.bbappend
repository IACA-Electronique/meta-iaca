FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI += "file://system.conf \
            file://ca.cert.pem \
            file://rauc-bootselect.sh"

# Keyring that the DEVICE uses to verify bundles (public CA cert only!)
RAUC_KEYRING_FILE = "ca.cert.pem"

RAUC_CONFIG_DIR = "/etc/rauc"

# Install the custom bootloader backend script
do_install:append() {
    install -d ${D}${RAUC_CONFIG_DIR}
    install -m 0755 ${WORKDIR}/rauc-bootselect.sh ${D}${RAUC_CONFIG_DIR}/rauc-bootselect
}