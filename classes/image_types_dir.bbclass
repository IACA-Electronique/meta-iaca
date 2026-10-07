# Custom image type: dir
#
# Create a directory who contains a boot.tar.gz and a rootfs.tar.gz files

IMAGE_CMD:dir() {
  WORK_OUTPUT_DIR=${TMPDIR}/${IMAGE_NAME}.dir

  ROOTFS_SRC_TAR_GZ="${IMGDEPLOYDIR}/${IMAGE_LINK_NAME}.tar.gz"

  ROOTFS_TAR_GZ=${WORK_OUTPUT_DIR}/rootfs.tar.gz
  BOOT_TAR_GZ=${WORK_OUTPUT_DIR}/boot.tar.gz

  BOOT_IMG=${WORKDIR}/boot.img
  BOOT_DIR=${WORK_OUTPUT_DIR}/boot

  FINAL_DIRNAME=${IMAGE_NAME}.dir
  FINAL_DIR_PATH=${DEPLOY_DIR_IMAGE}/${FINAL_DIRNAME}
  FINAL_LINK=${DEPLOY_DIR_IMAGE}/${IMAGE_LINK_NAME}.dir


  if [ ! -d "${IMAGE_ROOTFS}" ]; then
    bbfatal "Missing rootfs directory: ${IMAGE_ROOTFS}"
  fi

  if [ ! -f "${BOOT_IMG}" ]; then
    bbfatal "Missing boot file: ${BOOT_IMG}"
  fi

  if [ -d "${WORK_OUTPUT_DIR}" ] || [ -f "${WORK_OUTPUT_DIR}" ]; then
    rm -fr "$WORK_OUTPUT_DIR"
  else
    mkdir "$WORK_OUTPUT_DIR"
  fi

  # ROOTFS
  cp "${ROOTFS_SRC_TAR_GZ}" "${ROOTFS_TAR_GZ}" || { echo "Unable to copy rootfs '${ROOTFS_SRC_TAR_GZ}' to '${ROOTFS_TAR_GZ}'."; exit 1; }
  cd ${WORKDIR}

  # BOOT
  mkdir "$BOOT_DIR" || { echo "Unable to create temporary boot directory."; exit 1; }
  mcopy -v -i ${BOOT_IMG} -s ::*  ${BOOT_DIR} || { echo "Unable to extract boot data to directory (BOOT_DATA='${BOOT_IMG}', BOOT_DIR='${BOOT_DIR}')."; exit 1; }
  cd "${BOOT_DIR}"
  tar -cvzf "${BOOT_TAR_GZ}" .
  cd ${WORKDIR}
  rm -fr "$BOOT_DIR"

  mv "${WORK_OUTPUT_DIR}" "${FINAL_DIR_PATH}"

  if [ -e "$FINAL_LINK" ] || [ -L "$FINAL_LINK" ]; then
    rm "$FINAL_LINK"
  fi

  ln -s "$FINAL_DIRNAME" "$FINAL_LINK" || { echo "ERROR : Unable to create symlink from '$FINAL_LINK' to '$FINAL_DIRNAME'."; exit 1; }
}

IMAGE_TYPEDEP:dir = "tar.gz rpi-sdimg"