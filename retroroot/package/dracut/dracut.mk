################################################################################
#
# dracut
#
################################################################################

DRACUT_VERSION = 052
DRACUT_SITE = $(call github,dracutdevs,dracut,$(DRACUT_VERSION))
DRACUT_LICENSE = GPL-2.0
DRACUT_LICENSE_FILES = COPYING
DRACUT_INSTALL_STAGING = YES

# Dracut requires realpath from coreutils
# prelink-cross is used to determin which libraries to copy.
HOST_DRACUT_DEPENDENCIES += \
	host-pkgconf \
	host-kmod \
	host-coreutils \
	host-cpio \
	host-gzip \
	host-util-linux \
	host-prelink-cross

DRACUT_DEPENDENCIES += \
	host-dracut \
	kmod \
	pkgconf

DRACUT_MAKE_ENV += \
	CC="$(TARGET_CC)" \
	PKG_CONFIG="$(HOST_PKG_CONFIG_PATH)" \
	dracutsysrootdir=$(TARGET_DIR)

DRACUT_CONF_OPTS = --disable-documentation

HOST_DRACUT_MAKE_ENV += \
	PKG_CONFIG="$(HOST_PKG_CONFIG_PATH)"

HOST_DRACUT_CONF_OPTS = \
	--disable-documentation \
	--libdir=$(HOST_DIR)/lib \
	--libexecdir=$(HOST_DIR)/lib \
	--bindir=$(HOST_DIR)/bin \
	--sbindir=$(HOST_DIR)/sbin

ifeq ($(BR2_PACKAGE_BASH),y)
DRACUT_DEPENDENCIES += \
	bash \
	bash-completion
endif

# gensplash is gentoo specific
define DRACUT_REMOVE_UNEEDED_MODULES
	$(RM) -r $(TARGET_DIR)/usr/lib/dracut/modules.d/50gensplash
endef
DRACUT_TARGET_FINALIZE_HOOKS += DRACUT_REMOVE_UNEEDED_MODULES

define DRACUT_LINUX_CONFIG_FIXUPS
	$(call KCONFIG_ENABLE_OPT,CONFIG_BLK_DEV_INITRD)
	$(call KCONFIG_ENABLE_OPT,CONFIG_DEVTMPFS)
endef

ifeq ($(BR2_PACKAGE_SYSTEMD),y)

DRACUT_MAKE_ENV += \
	SYSTEMCTL=$(HOST_DIR)/usr/bin/systemctl

DRACUT_DEPENDENCIES += systemd
DRACUT_CONF_OPTS += --systemdsystemunitdir=/usr/lib/systemd/system
define DRACUT_REMOVE_SYSTEMD_FILES
	# Do not start dracut services normally. Dracut will enable the dracut
	# services during image creation.
	find $(TARGET_DIR)/etc/systemd/system -name "*dracut*.service" -delete
endef
DRACUT_TARGET_FINALIZE_HOOKS += DRACUT_REMOVE_SYSTEMD_FILES
endif

# Install the dracut-install wrapper which exports the proper LD_LIBRARY_PATH
# when called.
define HOST_DRACUT_INSTALL_WRAPPER
	$(INSTALL) -D -m 755 $(DRACUT_PKGDIR)/dracut-install.in \
		$(HOST_DIR)/bin/dracut-install
endef
HOST_DRACUT_POST_INSTALL_HOOKS += HOST_DRACUT_INSTALL_WRAPPER

$(eval $(autotools-package))
$(eval $(host-autotools-package))
