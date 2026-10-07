#!/bin/sh

set -e

case $1 in
  prereqs)
    exit 0
    ;;
esac

# ---------------------------------------------------------------------------------------------------------------------------------

OVERLAY_DIR=/overlay
OVERLAY_TMPFS_DIR=${OVERLAY_DIR}/tmpfs
OVERLAY_BASE_DIR=${OVERLAY_DIR}/base
OVERLAY_WORK_DIR=${OVERLAY_TMPFS_DIR}/work
OVERLAY_UPPER_DIR=${OVERLAY_TMPFS_DIR}/upper

ORIGINAL_ROOT=${ROOTMNT} # 'ROOTMNT' is populate by init script (generally it's /root)
FINAL_ROOT=${OVERLAY_DIR}/root

FINAL_ROOT_BASE=${FINAL_ROOT}/mnt/overlay/base
FINAL_ROOT_UPPER=${FINAL_ROOT}/mnt/overlay/upper

OVERLAY_SIZE=2G
# ---------------------------------------------------------------------------------------------------------------------------------

mkdir -p $OVERLAY_TMPFS_DIR

mount -t tmpfs -o size=$OVERLAY_SIZE tmpfs $OVERLAY_TMPFS_DIR

mkdir -p $OVERLAY_DIR $OVERLAY_TMPFS_DIR $OVERLAY_BASE_DIR $OVERLAY_UPPER_DIR $OVERLAY_WORK_DIR $FINAL_ROOT

mount --bind $ORIGINAL_ROOT $OVERLAY_BASE_DIR

mount -t overlay overlay -o lowerdir=${OVERLAY_BASE_DIR},upperdir=${OVERLAY_UPPER_DIR},workdir=${OVERLAY_WORK_DIR} $FINAL_ROOT

mkdir -p $FINAL_ROOT_BASE
mount --bind $OVERLAY_BASE_DIR $FINAL_ROOT_BASE

mkdir -p $FINAL_ROOT_UPPER
mount --bind $OVERLAY_UPPER_DIR $FINAL_ROOT_UPPER

exit 0