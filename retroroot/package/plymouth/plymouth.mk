################################################################################
#
# plymouth
#
################################################################################

PLYMOUTH_VERSION = 0.9.5
PLYMOUTH_SITE = $(call github,freedesktop,plymouth,$(PLYMOUTH_VERSION))
PLYMOUTH_LICENSE = GPL-2.0
PLYMOUTH_LICENSE_FILES = COPYING
PLYMOUTH_AUTORECONF = YES
PLYMOUTH_DEPENDENCIES = \
	cairo \
	dbus \
	libcap \
	libpng \
	ncurses \
	systemd

ifeq ($(call qstrip,$(BR2_PACKAGE_PLYMOUTH_BOOT_LOGO)),)
PLYMOUTH_BOOT_LOGO=/etc/plymouth/bizcom.png
else
PLYMOUTH_BOOT_LOGO=$(call qstrip,$(BR2_PACKAGE_PLYMOUTH_BOOT_LOGO))
endif

PLYMOUTH_CONF_OPTS = \
	--enable-systemd-integration \
	--enable-upstart-monitoring \
	--with-logo=$(PLYMOUTH_BOOT_LOGO) \
	--with-background-start-color-stop=0x0073B3 \
	--with-background-end-color-stop=0x00457E \
	--with-background-color=0x3391cd \
	--with-system-root-install

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

# This package uses autoconf, but not automake, so we need to call
# their special autogen.sh script.
# We still need to patch libtool after running the autogen.sh script, or else
# the make files will attempt to link to the host PC's directories.
define PLYMOUTH_RUN_AUTOGEN
	cd $(@D) && PATH=$(BR_PATH) AUTOCONF="$(AUTOCONF)" NOCONFIGURE=1 ./autogen.sh
endef
PLYMOUTH_PRE_CONFIGURE_HOOKS += PLYMOUTH_RUN_AUTOGEN
PLYMOUTH_PRE_CONFIGURE_HOOKS += LIBTOOL_PATCH_HOOK

$(eval $(autotools-package))
