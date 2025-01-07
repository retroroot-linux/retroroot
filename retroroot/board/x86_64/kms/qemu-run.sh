#!/usr/bin/env bash
set -ex
CWD="$(realpath "$(dirname "$0")")"
X64_QEMU="qemu-system-x86_64"
CPU=""
FONTCONFIG_PATH=/etc/fonts
LIBGL_DRIVERS_PATH=/usr/lib64/dri
OVMF="/usr/share/OVMF/OVMF_CODE.fd"
OVMF_VARS="/usr/share/OVMF/OVMF_VARS.fd"
DISK_IMG="$(realpath "${CWD}"/../../../images/retroroot-x64.img)"
QEMU_BRIDGE_HELPER="/usr/libexec/qemu-bridge-helper"

IS_UBUNTU=$(grep "Ubuntu" /etc/os-release || true)
if [ -n "${IS_UBUNTU}" ]; then
  LIBGL_DRIVERS_PATH="/usr/lib/x86_64-linux-gnu/dri"
  OVMF="/usr/share/OVMF/OVMF_CODE_4M.fd"
  OVMF_VARS="/usr/share/OVMF/OVMF_VARS_4M.fd"
  QEMU_BRIDGE_HELPER="/usr/lib/qemu/qemu-bridge-helper"
fi

check_env() {
  qemu=$(which "${X64_QEMU}" || true)
  if [ -z "${qemu}" ]; then
    echo "${X64_QEMU}: command not found!"
    exit 1
  fi
  if [ ! -d "${FONTCONFIG_PATH}" ]; then
    echo "Warning: ${FONTCONFIG_PATH} does not exist!"
  fi
  if [ ! -d "${LIBGL_DRIVERS_PATH}" ]; then
    echo "CRITICAL: ${LIBGL_DRIVERS_PATH} does not exist!"
    exit 1
  fi
  if [ ! -e "${OVMF}" ]; then

    echo "CRITICAL: ${OVMF} does not exist. Please install the edk2-ovmf package!"
    exit 1
  fi
  if [ ! -e "${OVMF_VARS}" ]; then
    echo "CRITICAL: ${OVMF_VARS} does not exist. Please install the edk2-ovmf package!"
    exit 1
  fi
  if [ ! -e "${DISK_IMG}" ]; then
    echo "CRITICAL: ${DISK_IMG} does not exit. Please build the x86_64_mender_defconfig image!"
    exit 1
  fi
}

check_cpu_features() {
  CPU=$(grep -m1 'GenuineIntel\|AuthenticAMD' /proc/cpuinfo |awk -F ' ' '{print $3}' || true)
  if [ -z "${CPU}" ]; then
    echo "CRITICAL: This script is only tested on Intel and AMD processors!"
    exit 1
  fi
  if [ ! -e /dev/kvm ]; then
    echo "Error: /dev/kvm does not exist. Please enable virtualization in either the BIOS or EUFI settings!"
    exit 1
  fi
}

run_virt() {
  LIBGL_DRIVERS_PATH="${LIBGL_DRIVERS_PATH}" \
  FONTCONFIG_PATH="${FONTCONFIG_PATH}" \
  qemu-system-x86_64 \
    -enable-kvm \
    -m 1024M \
    -M q35,accel=kvm \
    -cpu host \
    -drive if=pflash,format=raw,readonly=on,file="${OVMF}" \
    -drive if=pflash,format=raw,readonly=on,file="${OVMF_VARS}" \
    -smbios type=2 \
    -drive file="${DISK_IMG}",format=raw,id=pcu,if=none \
    -device ahci,id=ahci \
    -device ide-hd,drive=pcu,bus=ahci.0 \
    -net nic,model=virtio \
    -netdev bridge,br=virbr0,id=net0,helper="${QEMU_BRIDGE_HELPER}" -device virtio-net-pci,netdev=net0 \
    -net user \
    -device virtio-vga-gl \
    -display gtk,gl=on,show-cursor=on \
    -usb \
    -device usb-ehci,id=ehci \
    -device usb-tablet,bus=usb-bus.0
}

main() {
  check_env
  check_cpu_features
  run_virt
  exit 0
}

main "${@}"
