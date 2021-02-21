#!/usr/bin/env bash
set -e
DEVICE_TYPE="buildroot-x86_64"
ARTIFACT_NAME="1.0"
KERNEL_VERSION=$(grep 'BR2_LINUX_KERNEL_VERSION=' ${BR2_CONFIG} |awk -F'"' '{print $2}')

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

  # Create a persistent directory to mount the data partition at.
function mender_fixup(){
  cd ${TARGET_DIR}
  if [[ -L var/lib/mender ]]; then
    rm var/lib/mender
    mkdir -p var/lib/mender
  fi

  # The common paradigm is to have the persistent data volume at /data for mender.
  if [[ ! -L data ]]; then
      ln -s var/lib/mender data
  fi
}

function grub_fixup(){
  mkdir -p ${TARGET_DIR}/boot
  cp -rf ${BINARIES_DIR}/efi-part/* "${TARGET_DIR}/boot/"
  cp -rf ${BINARIES_DIR}/bzImage "${TARGET_DIR}/boot/vmlinuz-${KERNEL_VERSION}"
  cp -f "retroarch/board/x86_64/kms/grub.cfg" "${BINARIES_DIR}/efi-part/EFI/BOOT/grub.cfg"
  cp -f "retroarch/board/x86_64/kms/grub.cfg" "${TARGET_DIR}/boot/EFI/BOOT/grub.cfg"
}

function main(){
  parse_args "${@}"
  grub_fixup
  mender_fixup
  echo "device_type=${DEVICE_TYPE}" > ${TARGET_DIR}/etc/mender/device_type
  echo "artifact_name=${ARTIFACT_NAME}" > ${TARGET_DIR}/etc/mender/artifact_info
}

main "${@}"
