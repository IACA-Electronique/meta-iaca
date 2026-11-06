FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI += "file://system.conf file://ca.cert.pem"

# Keyring that the DEVICE uses to verify bundles (public CA cert only!)
RAUC_KEYRING_FILE = "ca.cert.pem"