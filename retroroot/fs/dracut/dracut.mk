################################################################################
#
# Build the dracut initramfs image
#
################################################################################

# Dracut requires realpath from coreutils
ROOTFS_DRACUT_DEPENDENCIES += \
	host-dracut \
	dracut

DRACUT_MODULES_INCLUDE = kernel-modules
DRACUT_MODULES_OMIT = dbus-broker

# Environment variables used to execute dracut
# We have to unset "prefix" as dracut uses it to move files around.
DRACUT_FS_ENV = \
	prefix="" \
	DESTROOTDIR="$(ROOTFS_DRACUT_DIR)/target" \
	DRACUT_ARCH=$(BR2_ARCH) \
	DRACUT_COMPRESS_BZIP2="$(HOST_DIR)/bin/bzip2" \
	DRACUT_COMPRESS_GZIP="$(HOST_DIR)/bin/gzip" \
	DRACUT_COMPRESS_LZMA="$(HOST_DIR)/bin/lzma" \
	DRACUT_FIRMWARE_PATH="$(ROOTFS_DRACUT_DIR)/target/usr/lib/firmware" \
	DRACUT_INSTALL="$(HOST_DIR)/bin/dracut-install" \
	DRACUT_INSTALL_PATH="$(ROOTFS_DRACUT_DIR)/target/usr/bin:$(ROOTFS_DRACUT_DIR)/target/usr/sbin:$(ROOTFS_DRACUT_DIR)/target/usr/lib" \
	DRACUT_LDCONFIG=/bin/true \
	DRACUT_LDD="$(HOST_DIR)/sbin/prelink-rtld --root=$(ROOTFS_DRACUT_DIR)/target/" \
	DRACUT_PATH="/usr/bin /usr/sbin" \
	INITRAMFS_VERSION=initramfs-$(LINUX_VERSION_PROBED).img \
	KERNEL_VERSION=$(LINUX_VERSION_PROBED) \
	STRIP_CMD="$(TARGET_CROSS)strip" \
	udevdir="$(ROOTFS_DRACUT_DIR)/target/usr/lib/udev"

ifeq ($(BR2_ROOTFS_DEVICE_TABLE_SUPPORTS_EXTENDED_ATTRIBUTES),y)
DRACUT_FS_ENV += DRACUT_NO_XATTR=true
else
DRACUT_FS_ENV += DRACUT_NO_XATTR=false
endif

ifeq ($(BR2_PACKAGE_BASH),y)
DRACUT_MODULES += bash
else
DRACUT_MODULES_OMIT += bash
endif

# Dracut typically executes busybox --list to get a list of installed busybox
# applets. Without a qemu wrapper, executing the busybox binary won't work in a
# cross-compiled environment. To avoid using a qemu-wrapper, we manually pass
# the list to Dracut using the busybox.links file that busybox creates when
# compiling.
ifeq ($(BR2_PACKAGE_BUSYBOX),y)
DRACUT_FS_ENV += \
	BUSYBOX_LIST=`sed -r -e s%.*/%%  $(BUSYBOX_DIR)/busybox.links;`
DRACUT_MODULES += busybox
else
DRACUT_MODULES_OMIT += busybox
endif

ifeq ($(BR2_PACKAGE_MKSH),y)
DRACUT_MODULES += mksh
else
DRACUT_MODULES_OMIT += mksh
endif

ifeq ($(BR2_PACKAGE_BTRFS_PROGS),y)
DRACUT_MODULES += btrfs
else
DRACUT_MODULES_OMIT += btrfs
endif

ifeq ($(BR2_PACKAGE_DASH),y)
DRACUT_MODULES += dash
else
DRACUT_MODULES_OMIT += dash
endif

ifeq ($(BR2_PACKAGE_PERL_I18N),y)
DRACUT_MODULES += i18n
else
DRACUT_MODULES_OMIT += i18n
endif

ifeq ($(BR2_PACKAGE_RNG_TOOLS),y)
DRACUT_MODULES += rngd
else
DRACUT_MODULES_OMIT += rngd
endif

ifeq ($(BR2_PACKAGE_LIBSELINUX),y)
DRACUT_MODULES += securityfs selinux
else
DRACUT_MODULES_OMIT += securityfs selinux
endif

ifeq ($(BR2_PACKAGE_SYSTEMD),y)
# Dracut doesn't support decimal points for the systemd version.
DRACUT_SYSTEMD_VERSION_SANATIZED=`echo $(SYSTEMD_VERSION) |cut -d . -f 1`
DRACUT_FS_ENV += \
	SYSTEMCTL="$(HOST_DIR)/bin/systemctl" \
	SYSTEMD_VERSION=$(DRACUT_SYSTEMD_VERSION_SANATIZED) \
	UDEVVERSION=$(DRACUT_SYSTEMD_VERSION_SANATIZED) \
	systemctlpath="$(HOST_DIR)/bin/systemctl" \
	systemdsystemconfdir="$(ROOTFS_DRACUT_DIR)/target/etc/systemd/system" \
	systemdsystemunitdir="$(ROOTFS_DRACUT_DIR)/target/lib/systemd/system" \
	systemdutildir="$(ROOTFS_DRACUT_DIR)/target/lib/systemd"
DRACUT_MODULES += systemd
else
DRACUT_MODULES_OMIT += systemd
endif

ifeq ($(BR2_PACKAGE_SYSTEMD_COREDUMP),y)
DRACUT_MODULES += systemd-coredump
else
DRACUT_MODULES_OMIT += systemd-coredump
endif

ifeq ($(BR2_PACKAGE_SYSTEMD_INITRD),y)
DRACUT_MODULES += systemd-initrd
else
DRACUT_MODULES_OMIT += systemd-initrd
endif

ifeq ($(BR2_PACKAGE_SYSTEMD_REPART),y)
DRACUT_MODULES += systemd-repart
else
DRACUT_MODULES_OMIT += systemd-repart
endif

ifeq ($(BR2_PACKAGE_SYSTEMD_SYSUSERS),y)
DRACUT_MODULES += systemd-sysusers
else
DRACUT_MODULES_OMIT += systemd-sysusers
endif

ifeq ($(BR2_PACKAGE_SYSTEMD_NETWORKD),y)
DRACUT_MODULES += systemd-networkd
else
DRACUT_MODULES_OMIT += systemd-networkd
endif

ifeq ($(BR2_PACKAGE_UTIL_LINUX_HWCLOCK),y)
DRACUT_MODULES += warpclock
else
DRACUT_MODULES_OMIT += warpclock
endif

ifeq ($(BR2_PACKAGE_ROOTFS_DRACUT_PLYMOUTH),y)
ROOTFS_DRACUT_DEPENDENCIES += plymouth
DRACUT_MODULES += plymouth
DRACUT_FS_ENV += \
	PLYMOUTH_CONFDIR=$(ROOTFS_DRACUT_DIR)/target/etc/plymouth \
	PLYMOUTH_DATADIR=$(ROOTFS_DRACUT_DIR)/target//usr/share \
	PLYMOUTH_POLICYDIR=$(ROOTFS_DRACUT_DIR)/target/usr/share/plymouth/ \
	PLYMOUTH_LOGO_FILE=$(ROOTFS_DRACUT_DIR)/target/etc/plymouth/bizcom.png \
	PLYMOUTH_LIBEXECDIR=$(ROOTFS_DRACUT_DIR)/target/usr/libexec \
	PLYMOUTH_LDD="$(HOST_DIR)/sbin/prelink-rtld --root=$(ROOTFS_DRACUT_DIR)/target/" \
	PLYMOUTH_LDD_PATH=/bin/true \
	PLYMOUTH_PLUGIN_PATH=$(ROOTFS_DRACUT_DIR)/target/usr/lib/plymouth \
	PLYMOUTH_THEME_NAME="spinner" \
	PLYMOUTH_THEME="spinner"
else
DRACUT_MODULES_OMIT += plymouth
endif

DRACUT_ROOTFS_BUILTIN_MODULES = $(call qstrip,$(BR2_PACKAGE_ROOTFS_KERNEL_MODULES))
DRACUT_MODULES += $(call qstrip,$(BR2_PACKAGE_ROOTFS_DRACUT_MODULES))
DRACUT_MKFS_CONF_OPTS = \
	--modules="$(DRACUT_MODULES)" \
	--omit="$(DRACUT_MODULES_OMIT)" \
	--drivers=$(DRACUT_ROOTFS_BUILTIN_MODULES) \
	--force \
	--fstab \
	--kernel-image="$(BINARIES_DIR)/$(LINUX_TARGET_NAME)" \
	--kmoddir="$(ROOTFS_DRACUT_DIR)/target/lib/modules/$(LINUX_VERSION_PROBED)" \
	--no-compress \
	--noprefix \
	--fakeroot=$(HOST_DIR)/bin/fakeroot \
	--sysroot="$(ROOTFS_DRACUT_DIR)/target" \
	--tmpdir=$(ROOTFS_DRACUT_DIR)/rootfs.dracut.tmp \
	--verbose

ifeq ($(BR2_PACKAGE_ROOTFS_DRACUT_HOST_ONLY),y)
DRACUT_MKFS_CONF_OPTS += --hostonly
else
DRACUT_MKFS_CONF_OPTS += --no-hostonly
endif

ifeq ($(BR2_PACKAGE_ROOTFS_DRACUT_MOD_SIG),y)
DRACUT_MODULES += modsign
else
DRACUT_MODULES_OMIT += modsign
endif

ifeq ($(BR2_STRIP_strip),y)
DRACUT_MKFS_CONF_OPTS += --strip
else
DRACUT_MKFS_CONF_OPTS += --nostrip
endif

ifeq ($(BR2_REPRODUCIBLE),y)
DRACUT_MKFS_CONF_OPTS += --reproducible
endif

define ROOTFS_DRACUT_BUILD
	(mkdir -p $(ROOTFS_DRACUT_DIR)/rootfs.dracut.tmp && \
		$(DRACUT_FS_ENV) \
		$(HOST_DIR)/bin/dracut \
		$(DRACUT_MKFS_CONF_OPTS) \
		$(BINARIES_DIR)/initramfs-$(LINUX_VERSION_PROBED).img \
		$(LINUX_VERSION_PROBED))
endef
ROOTFS_DRACUT_PRE_FAKEROOT_HOOKS += ROOTFS_DRACUT_BUILD

$(eval $(rootfs))
