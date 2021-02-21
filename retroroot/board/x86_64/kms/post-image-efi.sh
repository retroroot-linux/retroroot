#!/usr/bin/env bash
set -e
BOARD_DIR="$(realpath $(dirname $0))"
GENIMAGE_CFG="${BOARD_DIR}/genimage-efi.cfg"
DATA_PART_SIZE="32M"
DEVICE_TYPE="buildroot-x86_64"
GENERATE_MENDER_IMAGE="false"
ARTIFACT_NAME="1.0"


# Parse arguments.
function parse_args(){
    local o O opts
    o='a:o:d:g:'
    O='artifact-name:,data-part-size:,device-type:,generate-mender-image:'
    opts="$(getopt -n "${my_name}" -o "${o}" -l "${O}" -- "${@}")"
    eval set -- "${opts}"
    while [ ${#} -gt 0 ]; do
        case "${1}" in
        (-o|--data-part-size)
            DATA_PART_SIZE="${2}"; shift 2
            ;;
        (-d|--device-type)
            DEVICE_TYPE="${2}"; shift 2
            ;;
        (-g|--generate-mender-image)
            GENERATE_MENDER_IMAGE="${2}"; shift 2
            ;;
        (-a|--artifact-name)
            ARTIFACT_NAME="${2}"; shift 2
            ;;
        (--)
            shift; break
            ;;
        esac
    done
}


# Generate retroarch directories on the data partition.
function setup_retroarch(){
  DATA_PART="${BINARIES_DIR}"/data-part/
  mkdir -p "${DATA_PART}"/retroarch/
  mkdir -p "${DATA_PART}"/retroarch/{assets,cache,config,content,cores,databases,downloads,gui,info,logs,options,overlay,screenshots,thumbnails,video}
  mkdir -p "${DATA_PART}"/retroarch/options/core
  mkdir -p "${DATA_PART}"/retroarch/gui/rgui
  mkdir -p "${DATA_PART}"/retroarch/video/{layouts,shaders}
  mkdir -p "${DATA_PART}"/retroarch/config/{cheats,layouts,overlay,remaps,joypad,playlists,video_shaders,remaps}
  mkdir -p "${DATA_PART}"/retroarch/info
  cp -rf "${TARGET_DIR}"/etc/retroarch.cfg "${DATA_PART}"/retroarch/config/
  cp -rf "${TARGET_DIR}"/usr/share/libretro/assets/* "${DATA_PART}"/retroarch/assets/
}


# Create the data partition
function make_data_partition(){
    rm -rf "${BINARIES_DIR}/data-part.ext4"
    rm -rf "${BINARIES_DIR}/data-part"
    mkdir -p "${BINARIES_DIR}/data-part/ssh"
    setup_retroarch
    "${HOST_DIR}"/sbin/mkfs.ext4 \
    -d "${BINARIES_DIR}"/data-part \
    -r 1 \
    -N 0 \
    -m 5 \
    -L "data" \
    -O 64bit "${BINARIES_DIR}"/data-part.ext4 "${DATA_PART_SIZE}"
    "${HOST_DIR}"/sbin/e2fsck -y "${BINARIES_DIR}"/data-part.ext4
}


# Create a mender image.
function generate_mender_image(){
  if [[ ${GENERATE_MENDER_IMAGE} == "true" ]]; then
    echo "Creating ${BINARIES_DIR}/${DEVICE_TYPE}-${ARTIFACT_NAME}.mender"
    "${HOST_DIR}"/bin/mender-artifact \
      --compression lzma \
      write rootfs-image \
      -t "${DEVICE_TYPE}" \
      -n "${BR2_VERSION}" \
      -f "${BINARIES_DIR}/rootfs.ext2" \
      -o "${BINARIES_DIR}/${DEVICE_TYPE}-${ARTIFACT_NAME}.mender"
  fi
}


function uuid_fixup(){
  set -x
  ROOT_UUID=$(dumpe2fs "${BINARIES_DIR}/rootfs.ext2" 2>/dev/null | sed -n 's/^Filesystem UUID: *\(.*\)/\1/p')
  DATA_UUID=$(dumpe2fs "${BINARIES_DIR}/data-part.ext4" 2>/dev/null | sed -n 's/^Filesystem UUID: *\(.*\)/\1/p')
  sed "s/ROOT_UUID_TMP/${ROOT_UUID}/g" retroarch/board/x86_64/kms/genimage-efi.cfg > "${BINARIES_DIR}/genimage-efi.cfg"
  sed "s/DATA_UUID_TMP/${DATA_UUID}/g" -i "${BINARIES_DIR}/genimage-efi.cfg"
  sed -i "s/ROOT_UUID_TMP/${ROOT_UUID}/g" "${BINARIES_DIR}/efi-part/EFI/BOOT/grub.cfg"
}


function generate_image(){
    sh support/scripts/genimage.sh -c ${BINARIES_DIR}/genimage-efi.cfg
}


# Main function.
function main(){
  parse_args "${@}"
  make_data_partition
  uuid_fixup
  generate_image
  generate_mender_image
  cp "${BINARIES_DIR}/disk.img" ${PWD}/build/output/disk.img
  exit $?
}

main "${@}"
