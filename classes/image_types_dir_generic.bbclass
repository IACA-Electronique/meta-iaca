# Custom image type: dir_generic
#
# Create a directory containing boot.tar.gz and rootfs.tar.gz.
# Generic implementation that works for any machine (Raspberry Pi, Banana Pi, etc.).
#
# Output layout:
#   ${DEPLOY_DIR_IMAGE}/${IMAGE_NAME}.dir/
#     ├── boot.tar.gz
#     └── rootfs.tar.gz
#
# Required variable:
#   IMAGE_DIR_GENERIC_BOOT_FILES — space-separated list of entries present in
#                                  ${IMGDEPLOYDIR} to include in boot.tar.gz.
#                                  Entries may be files or directories.
#                                  Directories are copied recursively with
#                                  their whole content (e.g. device tree
#                                  overlays directories).
#                                  Optional "source;target" syntax renames the
#                                  entry in the boot directory. Without ';',
#                                  the target name is the same as the source
#                                  name.
#                                  A source ending in "/*" (e.g. "toto/*")
#                                  copies only the content of the directory:
#                                  with "toto/*" and tata/tutu inside toto,
#                                  the boot directory gets tata and tutu, not
#                                  a toto/ subdirectory. Combined with
#                                  "source;target", the content is placed
#                                  inside the target directory.
#                                  Must be set in the image recipe.

# List of boot file names found in ${IMGDEPLOYDIR} (must be set in the image recipe)
IMAGE_DIR_GENERIC_BOOT_FILES ?= ""

# Rootfs is always sourced from tar.gz
IMAGE_TYPEDEP:dir_generic = "tar.gz"

# Boot files are deployed by the kernel and bootloader recipes
do_image_dir_generic[depends] += "virtual/kernel:do_deploy virtual/bootloader:do_deploy"

# Split a boot file entry into source and target names.
# Optional "source;target" syntax: before ';' is the source file name in
# ${DEPLOY_DIR_IMAGE}, after ';' is the target name in the boot directory.
# Without ';', source and target are the same. Results are returned via the
# variable named by <src_var> and <dst_var>.
parse_boot_file_name() {
    entry="$1"
    src_var="$2"
    dst_var="$3"
    case "${entry}" in
        *\;*)
            eval "${src_var}=\${entry%%\\;*}"
            eval "${dst_var}=\${entry##*;}"
            ;;
        *)
            eval "${src_var}=\${entry}"
            eval "${dst_var}=\${entry}"
            ;;
    esac
}

IMAGE_CMD:dir_generic() {
    WORK_OUTPUT_DIR=${TMPDIR}/${IMAGE_NAME}.dir
    FINAL_DIRNAME=${IMAGE_NAME}.dir
    FINAL_DIR_PATH=${DEPLOY_DIR_IMAGE}/${FINAL_DIRNAME}
    FINAL_LINK=${DEPLOY_DIR_IMAGE}/${IMAGE_LINK_NAME}.dir

    ROOTFS_SRC_TAR_GZ="${IMGDEPLOYDIR}/${IMAGE_NAME}.tar.gz"
    ROOTFS_TAR_GZ=${WORK_OUTPUT_DIR}/rootfs.tar.gz
    BOOT_TAR_GZ=${WORK_OUTPUT_DIR}/boot.tar.gz

    # --- Validate inputs ---
    if [ ! -d "${IMAGE_ROOTFS}" ]; then
        bbfatal "Missing rootfs directory: ${IMAGE_ROOTFS}"
    fi

    if [ ! -f "${ROOTFS_SRC_TAR_GZ}" ]; then
        bbfatal "Missing rootfs tar.gz: ${ROOTFS_SRC_TAR_GZ}"
    fi

    BOOT_FILES="${IMAGE_DIR_GENERIC_BOOT_FILES}"
    if [ -z "${BOOT_FILES}" ]; then
        bbfatal "IMAGE_DIR_GENERIC_BOOT_FILES is not set. Define it in the image recipe."
    fi

    # --- Prepare work directory ---
    rm -fr "${WORK_OUTPUT_DIR}"
    mkdir -p "${WORK_OUTPUT_DIR}"

    # --- ROOTFS ---
    cp "${ROOTFS_SRC_TAR_GZ}" "${ROOTFS_TAR_GZ}" || {
        bbfatal "Unable to copy rootfs '${ROOTFS_SRC_TAR_GZ}' to '${ROOTFS_TAR_GZ}'"
    }

    # --- BOOT ---
    BOOT_DIR=${WORK_OUTPUT_DIR}/boot
    mkdir -p "${BOOT_DIR}"

    for f in ${BOOT_FILES}; do
        parse_boot_file_name "${f}" src dst
        case "${src}" in
            *\/*)
                # "dir/*" entry: copy only the content of <dir> into the
                # target location, without the directory base name.
                src_dir=${src%\/*}
                if [ ! -d "${DEPLOY_DIR_IMAGE}/${src_dir}" ]; then
                    bbfatal "Boot directory '${src_dir}' not found in ${DEPLOY_DIR_IMAGE} (listed in IMAGE_DIR_GENERIC_BOOT_FILES)"
                fi
                # Target directory: boot root when no explicit target was
                # given (dst defaulted to "dir/*"), otherwise the target with
                # any trailing "/*" stripped.
                if [ "${dst}" = "${src}" ]; then
                    dst_dir="."
                else
                    dst_dir=${dst%\/*}
                fi
                mkdir -p "${BOOT_DIR}/${dst_dir}"
                cp -r "${DEPLOY_DIR_IMAGE}/${src_dir}/." "${BOOT_DIR}/${dst_dir}/"
                ;;
            *)
                # Create intermediate directories of the target path if the
                # target base directory does not exist (e.g. "toto;dir/toto"
                # creates boot/dir).
                dst_dir=${dst%/*}
                if [ -n "${dst_dir}" ] && [ "${dst_dir}" != "${dst}" ]; then
                    mkdir -p "${BOOT_DIR}/${dst_dir}"
                fi
                if [ -d "${DEPLOY_DIR_IMAGE}/${src}" ]; then
                    # Directory entry: copy it recursively (with its content) into
                    # the boot directory under the target name.
                    cp -r "${DEPLOY_DIR_IMAGE}/${src}" "${BOOT_DIR}/${dst}"
                elif [ -f "${DEPLOY_DIR_IMAGE}/${src}" ]; then
                    cp "${DEPLOY_DIR_IMAGE}/${src}" "${BOOT_DIR}/${dst}"
                else
                    bbfatal "Boot entry '${src}' not found in ${DEPLOY_DIR_IMAGE} (listed in IMAGE_DIR_GENERIC_BOOT_FILES)"
                fi
                ;;
        esac
    done

    tar -cvzf "${BOOT_TAR_GZ}" -C "${BOOT_DIR}" . || {
        bbfatal "Unable to create boot tar.gz at '${BOOT_TAR_GZ}'"
    }
    rm -fr "${BOOT_DIR}"

    # --- Finalize: move to deploy dir and create symlink ---
    rm -fr "${FINAL_DIR_PATH}"
    mv "${WORK_OUTPUT_DIR}" "${FINAL_DIR_PATH}"

    if [ -e "${FINAL_LINK}" ] || [ -L "${FINAL_LINK}" ]; then
        rm -f "${FINAL_LINK}"
    fi

    ln -s "${FINAL_DIRNAME}" "${FINAL_LINK}" || { bbfatal "Unable to create symlink '${FINAL_LINK}' -> '${FINAL_DIRNAME}'"; }
}
