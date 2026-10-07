# Custom image type: iaca_a_b
#
# Purpose : Create IACA image with partition A/B support
# See : https://gitlab.iaca-electronique.com/linux/iaca-image-format-specifications
# Supported version : 2.x.x


IMAGE_CMD:iaca_a_b() {
    add_file_in_tar_archive() {
        local archive=$1
        local file_to_add=$2
        local tmp_file=archive.tar

        local file_to_add_dir=$(dirname "$file_to_add")
        local file_to_add_name=$(basename "$file_to_add")

        gunzip -c "$archive" > "${tmp_file}" || { echo "ERROR: Unable to uncompress '$archive'."; return 1; }

        tar -rf "$tmp_file" --owner=root --group=root -C "$file_to_add_dir" "./${file_to_add_name}" || {
                    echo "ERROR: Unable to add '$file_to_add' to archive '$tmp_file'.";
                    return 3;
                }

        gzip -c "$tmp_file" > "$archive" || { echo "ERROR: Unable compress '$tmp_file' to '$archive'."; return 4; }

        rm -f "$tmp_file"
    }


    update_root_from_boot_archive(){
        local archive=$1
        local root_part_device=$2
        local tmp_file=archive.tar

        gunzip -c "$archive" > "${tmp_file}" || { echo "ERROR: Unable to uncompress '$archive'."; return 1; }

        tar -xf "$tmp_file" "./cmdline.txt" || { echo "ERROR: Unable to extract cmdline.txt from '$archive'."; return 2; }

        sed -i -E "s#root=[^ ]+#root=${root_part_device}#" cmdline.txt || { echo "ERROR: Unable to update cmdline.txt from '$archive'."; return 3; }

        tar -uf "$tmp_file" "./cmdline.txt" || { echo "ERROR: Unable to update cmdline.txt to '$archive'."; return 4; }

        gzip -c "$tmp_file" > "$archive" || { echo "ERROR: Unable compress '$archive'."; return 5; }
    }


    install -d ${WORKDIR}/iaca-assets

    IMAGE_DIR_FORMAT_PATH=${DEPLOY_DIR_IMAGE}/${IMAGE_LINK_NAME}.dir

    BOOT_TAR_GZ=${IMAGE_DIR_FORMAT_PATH}/boot.tar.gz
    ROOTFS_TAR_GZ=${IMAGE_DIR_FORMAT_PATH}/rootfs.tar.gz

    WORK_OUTPUT_DIR=${TMPDIR}/${IMAGE_NAME}_a_b.tmp

    FINAL_IMAGE_PATH=${DEPLOY_DIR_IMAGE}/${IMAGE_NAME}_a_b.iaca
    FINAL_LINK_IMAGE_PATH=${DEPLOY_DIR_IMAGE}/${IMAGE_LINK_NAME}_a_b.iaca

    mkdir "$WORK_OUTPUT_DIR"

    cp "$BOOT_TAR_GZ" "${WORK_OUTPUT_DIR}/0.tar.gz" || { echo "ERROR : Unable to copy boot A."; exit 1; }
    cp "$BOOT_TAR_GZ" "${WORK_OUTPUT_DIR}/1.tar.gz" || { echo "ERROR : Unable to copy boot B."; exit 1; }

    add_file_in_tar_archive "${WORK_OUTPUT_DIR}/0.tar.gz" "${DEPLOY_DIR_IMAGE}/a_b/autoboot.txt" || { echo "ERROR : Unable to add autoboot.txt file in boot A."; exit 1; }

    cp "$ROOTFS_TAR_GZ" "${WORK_OUTPUT_DIR}/2" || { echo "ERROR : Unable to copy rootfs."; exit 2; }

    update_root_from_boot_archive "${WORK_OUTPUT_DIR}/0.tar.gz" "/dev/mmcblk0p3" || { echo "ERROR: Unable to update rootfs in boot A."; exit 3; }
    update_root_from_boot_archive "${WORK_OUTPUT_DIR}/1.tar.gz" "/dev/mmcblk0p4" || { echo "ERROR: Unable to update rootfs in boot B."; exit 3; }

    mv "${WORK_OUTPUT_DIR}/0.tar.gz" "${WORK_OUTPUT_DIR}/0" || { echo "ERROR : Unable to rename boot A."; exit 2; }
    mv "${WORK_OUTPUT_DIR}/1.tar.gz" "${WORK_OUTPUT_DIR}/1" || { echo "ERROR : Unable to rename boot B."; exit 2; }

    cp "${DEPLOY_DIR_IMAGE}/16GB_a_b.json" "${WORK_OUTPUT_DIR}/ifd.json" || { echo "ERROR : Unable to create ifd."; exit 3; }

    cd "${WORK_OUTPUT_DIR}"
    tar -cvf "${FINAL_IMAGE_PATH}" *  || { echo "ERROR : Unable to create archive."; exit 4; }

    [ -f "$FINAL_LINK_IMAGE_PATH" ] && rm "$FINAL_LINK_IMAGE_PATH"
    ln -s "${FINAL_IMAGE_PATH}" "$FINAL_LINK_IMAGE_PATH"

    # Clear
    rm -fr "$WORK_OUTPUT_DIR"
}

IMAGE_TYPEDEP:iaca_a_b = "dir"

do_image_iaca[depends] += "iaca-assets:do_deploy"