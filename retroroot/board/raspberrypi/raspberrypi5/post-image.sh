#!/usr/bin/env bash
set -eux
BOARD_DIR="$(realpath "$(dirname "$0")")"
CONFIG_TXT="${BOARD_DIR}/config.txt"
GENIMAGE_CFG="${BINARIES_DIR}/genimage.cfg"
RPI_FIRMWARE_OVERLAY_FILES_DIR="${BINARIES_DIR}/rpi-firmware/overlays"
IMAGE_DIR="$(realpath "${BOARD_DIR}"/../../../images)"
DEVICE_TYPE="rpi5"
source "${BOARD_DIR}"/../common/post-image-include
source "${BOARD_DIR}"/../../common/post-image-include


generate_image() {
  cp "${BOARD_DIR}"/config.txt "${BINARIES_DIR}"/config.txt
  UUID_ROOT=$(dumpe2fs "${BINARIES_DIR}/rootfs.ext2" 2>/dev/null | sed -n 's/^Filesystem UUID: *\(.*\)/\1/p' || true)
  UUID_DATA=$(dumpe2fs "${BINARIES_DIR}/data-part.ext4" 2>/dev/null | sed -n 's/^Filesystem UUID: *\(.*\)/\1/p' || true)
  sed "s/UUID_ROOT_TMP/${UUID_ROOT}/g" -i "${BINARIES_DIR}/genimage.cfg"
  sed "s/DISK_IMG/${DEVICE_TYPE}.img/g" -i "${BINARIES_DIR}/genimage.cfg"
  sed "s/UUID_DATA_TMP/${UUID_DATA}/g" -i "${BINARIES_DIR}/genimage.cfg"
  bash support/scripts/genimage.sh -c "${BINARIES_DIR}"/genimage.cfg
}



main(){
  parse_args "${@}"
  make_data_partition "64bit"
  parse_rpi_firmware_overlay_files
  generate_image
  copy_image
  exit $?
}

main "${@}"
