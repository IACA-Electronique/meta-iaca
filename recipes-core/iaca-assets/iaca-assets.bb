SUMMARY = "Deploy custom assets"
LICENSE = "CLOSED"

SRC_URI = " \
    file://16GB.json \
    file://16GB_a_b.json \
    file://a_b/autoboot.txt \
"

inherit deploy

do_deploy() {
    install -d ${DEPLOYDIR}
    install -d ${DEPLOYDIR}/a_b

    install -m 0644 ${UNPACKDIR}/16GB.json ${DEPLOYDIR}/16GB.json
    install -m 0644 ${UNPACKDIR}/16GB_a_b.json ${DEPLOYDIR}/16GB_a_b.json
    install -m 0644 ${UNPACKDIR}/a_b/autoboot.txt ${DEPLOYDIR}/a_b/autoboot.txt
}

addtask deploy after do_install before do_build