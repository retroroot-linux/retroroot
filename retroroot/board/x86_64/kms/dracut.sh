#!/usr/bin/env bash
# We have to unset "prefix" as dracut uses it to move files around.
# Yocto has it set as part of the build environment.
export prefix=
PACKAGE_DIR=$(realpath "${BASE_DIR}/../../../package")

XATTRS=$(grep "BR2_ROOTFS_DEVICE_TABLE_SUPPORTS_EXTENDED_ATTRIBUTES=y" ${BR2_CONFIG})
if [ -z "${XATTRS}" ]; then
  export DRACUT_NO_XATTR=true
else
  export DRACUT_NO_XATTR=false
fi

set -e

# DRACUT settings
export SYSTEMD_VERSION=$(grep "VERSION =" ${PACKAGE_DIR}/systemd/systemd.mk |awk -F '= ' '{print $2}' |awk -F'.' '{print $1}')
export UDEVVERSION=${SYSTEMD_VERSION}
export DRACUT_TMPDIR=$(mktemp -d)
export DRACUT_LDCONFIG=/bin/true
export DRACUT_COMPRESS_GZIP="${HOST_DIR}/bin/gzip"
export DRACUT_COMPRESS_BZIP2="${HOST_DIR}/bin/bzip2"
export DRACUT_COMPRESS_LZMA="${HOST_DIR}/bin/lzma"
export KERNEL_VERSION=$(grep 'BR2_LINUX_KERNEL_VERSION=' ${BR2_CONFIG} |awk -F'"' '{print $2}')
export DRACUT_ARCH=$(grep 'BR2_ARCH=' ${BR2_CONFIG} |awk -F'"' '{print $2}')
export DRACUT_INSTALL="${HOST_DIR}/lib/dracut/dracut-install"
export DRACUT_INSTALL_PATH="${TARGET_DIR}/usr/bin:${TARGET_DIR}/usr/sbin:${TARGET_DIR}/usr/lib"
export DRACUT_PATH="/usr/bin /usr/sbin"
export DRACUT_LDD="${HOST_DIR}/sbin/prelink-rtld --root=${TARGET_DIR}/"
export DESTROOTDIR="${TARGET_DIR}"
export systemctlpath="${HOST_DIR}/bin/systemctl"
export systemdutildir="${TARGET_DIR}/lib/systemd"
export systemdsystemunitdir="${TARGET_DIR}/lib/systemd/system"
export systemdsystemconfdir="${TARGET_DIR}/etc/systemd/system"
export udevdir="${TARGET_DIR}/usr/lib/udev"
export INITRAMFS_VERSION="initramfs-${KERNEL_VERSION}.img"
export PLYMOUTH_LDD="${HOST_DIR}/sbin/prelink-rtld --root=${TARGET_DIR}/"
export PLYMOUTH_LDD_PATH=/bin/true
export PLYMOUTH_THEME_NAME="spinner"
export PLYMOUTH_THEME="spinner"


${HOST_DIR}/bin/dracut \
--verbose \
--force \
--reproducible \
--noprefix \
--no-hostonly \
--sysroot ${TARGET_DIR} \
--tmpdir ${DRACUT_TMPDIR} \
--kmoddir ${TARGET_DIR}/lib/modules/${KERNEL_VERSION} \
--kernel-image ${BINARIES_DIR}/bzImage \
--no-compress \
${BINARIES_DIR}/initramfs-${KERNEL_VERSION}.img \
${KERNEL_VERSION}

rm -rf ${DRACUT_TMPDIR}

cp ${TARGET_DIR}/boot/vmlinuz-${KERNEL_VERSION} ${BINARIES_DIR}/vmlinuz-${KERNEL_VERSION}
