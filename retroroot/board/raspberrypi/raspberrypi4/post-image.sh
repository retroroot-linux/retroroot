#!/usr/bin/env bash
set -e
CWD=$(pwd)
BOARD_DIR="$(realpath "$(dirname "$0")")"
DEVICE_TYPE="rpi4"
GENIMAGE_CFG="${BOARD_DIR}/genimage.cfg"
GENIMAGE_TMP="${BUILD_DIR}/genimage.tmp"
PRODUCTION_DIR="${CWD}/retroroot/images/${DEVICE_TYPE}"
MENDER_ARTIFACT="false"
DATA_PART_SIZE="32M"
WEEK_NUM=$(date +%V)
VERSION="false"

parse_args(){
    local o O opts
    o='o:d:m:v:'
    O='data-part-size:,device-type:,mender-artifact:,version:'
    opts="$(getopt -o "${o}" -l "${O}" -- "${@}")"
    eval set -- "${opts}"
    while [ ${#} -gt 0 ]; do
        case "${1}" in
        (-m|--mender-artifact)
            MENDER_ARTIFACT="${2}"; shift 2
            ;;
        (-d|--device-type)
            DEVICE_TYPE="${2}"; shift 2
            ;;
        (-o|--data-part-size)
            DATA_PART_SIZE="${2}"; shift 2
            ;;
        (-v|--version)
          VERSION="${2}"; shift 2
          ;;
        (--)
            shift; break
            ;;
        esac
    done
    if [ "${VERSION}" == "false" ]; then
      echo "Version not set!"
      exit 1
    fi
    PRODUCTION_DIR="${CWD}/retroroot/production/${DEVICE_TYPE}"
}

create_mender_image(){
  echo "Generating ${PRODUCTION_DIR}/${DEVICE_TYPE}-${VERSION}-${WEEK_NUM}.mender"
  "${BASE_DIR}/host/usr/bin/mender-artifact" \
    --compression lzma \
    write rootfs-image \
    --no-checksum-provide \
    -t "${DEVICE_TYPE}" \
    -n "${VERSION}-${WEEK_NUM}" \
    -f "${BASE_DIR}/images/rootfs.ext2" \
    -o "${PRODUCTION_DIR}/${DEVICE_TYPE}-${VERSION}-${WEEK_NUM}.mender"
}

make_ext4_image(){
  PART_DIR="${1}"
  PART_LABEL="${2}"
  PART_NAME="${PART_LABEL}.ext4"

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
    "${BINARIES_DIR}/${PART_NAME}" "${DATA_PART_SIZE}"
}

make_extra_partitions(){
  make_ext4_image "${BINARIES_DIR}/data_part" "data"
}

create_image(){
  rm -rf "${GENIMAGE_TMP}"
  mkdir -p "${PRODUCTION_DIR}"
  mkdir -p "${TARGET_DIR}/etc/mender/"
  cp "${BOARD_DIR}"/genimage.cfg.in "${BINARIES_DIR}"/genimage.cfg
  sed s#@INITRD@#initrd-5.4.83-v7l.img#g -i "${BINARIES_DIR}"/genimage.cfg
  
  echo "artifact_name=${VERSION}-${WEEK_NUM}" > "${TARGET_DIR}/etc/mender/artifact_info"
  echo "device_type=${DEVICE_TYPE}" > "${TARGET_DIR}/etc/mender/device_type"

  if [[ -e "${BINARIES_DIR}/config.txt" ]]; then
    rm -rf "${BINARIES_DIR}/config.txt"
  fi
  cp -drpf "${BOARD_DIR}/config.txt" "${BINARIES_DIR}/config.txt"
  rm -rf "${BINARIES_DIR}/EFI"
  cp -rf "${BINARIES_DIR}"/efi-part/EFI "${BINARIES_DIR}"/EFI

  genimage \
    --rootpath "${ROOTPATH_TMP}" \
    --tmppath "${GENIMAGE_TMP}" \
    --inputpath "${BINARIES_DIR}" \
    --outputpath "${BINARIES_DIR}" \
    --config "${BINARIES_DIR}/genimage.cfg"
}

finalize(){
  mkdir -p "${PRODUCTION_DIR}"
  echo "cp ${BINARIES_DIR}/sdcard.img ${PRODUCTION_DIR}/${DEVICE_TYPE}.img"
  cp "${BINARIES_DIR}/sdcard.img" "${PRODUCTION_DIR}/${DEVICE_TYPE}.img"
  if [ "${MENDER_ARTIFACT}" == "true" ]; then
    create_mender_image
  fi
  exit $?
}

main(){
  parse_args "${@}"
  make_extra_partitions
  create_image
  finalize
  exit 0
}

main "${@}"
