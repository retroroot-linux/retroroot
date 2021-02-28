#!/usr/bin/env bash
set -e

BOARD_DIR="$(dirname "$0")"
DEVICE_TYPE="rpi3"
GENIMAGE_CFG="${BOARD_DIR}/genimage.cfg"
GENIMAGE_TMP="${BUILD_DIR}/genimage.tmp"
PRODUCTION_DIR="${CWD}/retroroot/images/${DEVICE_TYPE}"

create_image(){
  rm -rf "${GENIMAGE_TMP}"
  mkdir -p "${PRODUCTION_DIR}"

  genimage \
    --rootpath "${ROOTPATH_TMP}" \
    --tmppath "${GENIMAGE_TMP}" \
    --inputpath "${BINARIES_DIR}" \
    --outputpath "${BINARIES_DIR}" \
    --config "${BOARD_DIR}/genimage.cfg"

  echo "cp ${BINARIES_DIR}/${DEVICE_TYPE}.img ${PRODUCTION_DIR}/${DEVICE_TYPE}.img"
  cp "${BINARIES_DIR}/${DEVICE_TYPE}.img" "${PRODUCTION_DIR}/${DEVICE_TYPE}.img"
}

make_ext4_image(){
  PART_DIR="${1}"
  PART_LABEL="${2}"
  PART_SIZE="${3}"
  PART_NAME="${PART_LABEL}-part.ext4"

  cd "${BINARIES_DIR}"
  rm -rf "${PART_DIR}"
  rm -rf "${PART_NAME}"

  mkdir -p "${PART_DIR}"
  "${HOST_DIR}/sbin/mkfs.ext4" \
    -d "${PART_DIR}" \
    -r 1 \
    -m 5 \
    -L "${PART_LABEL}" \
    -O ^64bit \
    "${BINARIES_DIR}/${PART_NAME}" "${PART_SIZE}"
}


make_extra_partitions(){
  make_ext4_image "${BINARIES_DIR}/data_part" "data" "128M"
}

main(){
  make_extra_partitions
  create_image
  exit 0
}

main "${@}"
