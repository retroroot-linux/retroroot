#!/usr/bin/env bash
set -ue
BOARD_DIR="$(dirname "$0")"

# Add a console on tty1
if [ -e "${TARGET_DIR}"/etc/inittab ]; then
    grep -qE '^tty1::' "${TARGET_DIR}"/etc/inittab || \
	sed -i '/GENERIC_SERIAL/a\
tty1::respawn:/sbin/getty -L  tty1 0 vt100 # HDMI console' "${TARGET_DIR}"/etc/inittab
fi

cp "${BOARD_DIR}/config.txt" "${BINARIES_DIR}/config.txt"
cp "${BOARD_DIR}/cmdline.txt" "${BINARIES_DIR}/cmdline.txt"
