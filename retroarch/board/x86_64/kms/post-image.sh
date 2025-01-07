#!/usr/bin/env bash
set -e
BOARD_DIR="$(realpath "$(dirname "$0")")"
source "${BOARD_DIR}"/../../common/post-image-include
IMAGE_DIR="$(realpath "${BOARD_DIR}"/../../../images)"
DEVICE_TYPE="retroroot-kms-x86_64"


generate_image() {
  UUID_ROOT=$(dumpe2fs "${BINARIES_DIR}/rootfs.ext2" 2>/dev/null | sed -n 's/^Filesystem UUID: *\(.*\)/\1/p' || true)
  UUID_DATA=$(dumpe2fs "${BINARIES_DIR}/data-part.ext4" 2>/dev/null | sed -n 's/^Filesystem UUID: *\(.*\)/\1/p' || true)
  sed "s/UUID_ROOT_TMP/${UUID_ROOT}/g" "${BOARD_DIR}"/genimage.cfg > "${BINARIES_DIR}/genimage.cfg"
  sed "s/DISK_IMG/${DEVICE_TYPE}.img/g" -i "${BINARIES_DIR}/genimage.cfg"
  sed "s/UUID_ROOT_TMP/${UUID_ROOT}/g" -i "${BINARIES_DIR}/efi-part/EFI/BOOT/grub.cfg"
  sed "s/UUID_DATA_TMP/${UUID_DATA}/g" -i "${BINARIES_DIR}/genimage.cfg"
  bash support/scripts/genimage.sh -c "${BINARIES_DIR}"/genimage.cfg
}


copy_images() {
  MENDER_IMAGE="${DEVICE_TYPE}"-"${ARTIFACT_NAME}".mender
  mkdir -p "${IMAGE_DIR}"
  cp -rf "${BINARIES_DIR}"/"${DEVICE_TYPE}".img "${IMAGE_DIR}"/"${DEVICE_TYPE}".img
  if [[ -e ${BINARIES_DIR}"/${MENDER_IMAGE}" ]]; then
     cp -rf "${BINARIES_DIR}"/"${MENDER_IMAGE}" "${IMAGE_DIR}"/"${MENDER_IMAGE}"
  fi
}


main(){
  parse_args "${@}"
  make_data_partition "64bit"
  generate_image
  copy_images
  exit $?
}
main "${@}"
