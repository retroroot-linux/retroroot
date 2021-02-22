################################################################################
#
# plymouth
#
################################################################################

PLYMOUTH_VERSION = 0.9.5
PLYMOUTH_SITE = $(call github,freedesktop,plymouth,$(PLYMOUTH_VERSION))
PLYMOUTH_LICENSE = GPL-2.0
PLYMOUTH_LICENSE_FILES = COPYING
PLYMOUTH_DEPENDENCIES = \
	libcap \
	libpng \
	cairo \
	dbus \
	udev

ifeq ($(call qstrip,$(BR2_PACKAGE_PLYMOUTH_BOOT_LOGO)),)
PLYMOUTH_BOOT_LOGO=/etc/plymouth/bizcom.png
else
PLYMOUTH_BOOT_LOGO=$(call qstrip,$(BR2_PACKAGE_PLYMOUTH_BOOT_LOGO))
endif

PLYMOUTH_CONF_OPTS = \
	--with-logo=$(PLYMOUTH_BOOT_LOGO) \
	--with-background-start-color-stop=0x0073B3 \
	--with-background-end-color-stop=0x00457E \
	--with-background-color=0x3391cd

ifeq ($(BR2_ROOTFS_MERGED_USR),y)
PLYMOUTH_CONF_OPTS += --with-system-root-install
else
PLYMOUTH_CONF_OPTS += --without-system-root-install
endif

ifeq ($(BR2_PACKAGE_LIBDRM),y)
PLYMOUTH_DEPENDENCIES += libdrm
PLYMOUTH_CONF_OPTS += --enable-drm
else
PLYMOUTH_CONF_OPTS += --disable-drm
endif

ifeq ($(BR2_PACKAGE_LIBGTK3),y)
PLYMOUTH_DEPENDENCIES += libgtk3
PLYMOUTH_CONF_OPTS += --enable-gtk
else
PLYMOUTH_CONF_OPTS += --disable-gtk
endif

ifeq ($(BR2_PACKAGE_PANGO),y)
PLYMOUTH_DEPENDENCIES += pango
PLYMOUTH_CONF_OPTS += --enable-pango
else
PLYMOUTH_CONF_OPTS += --disable-pango
endif

ifeq ($(BR2_PACKAGE_SYSTEMD),y)
PLYMOUTH_DEPENDENCIES += systemd
PLYMOUTH_CONF_OPTS += --enable-systemd-integration
else
PLYMOUTH_CONF_OPTS += --disable-systemd-integration
endif

# This package uses autoconf, but not automake, so we need to call
# their special autogen.sh script, and have custom target and staging
# installation commands.
# We still need to patch libtool after running the autogen.sh script, or else
# the make files will attempt to link to the host directories.
define PLYMOUTH_RUN_AUTOGEN
	cd $(@D) && PATH=$(BR_PATH) NOCONFIGURE="1" ./autogen.sh
endef
PLYMOUTH_PRE_CONFIGURE_HOOKS += PLYMOUTH_RUN_AUTOGEN
PLYMOUTH_PRE_CONFIGURE_HOOKS += LIBTOOL_PATCH_HOOK

$(eval $(autotools-package))
