################################################################################
#
# retroarch-assets
#
################################################################################

RETROARCH_ASSETS_VERSION = 1.19.0
RETROARCH_ASSETS_SITE = $(call github,libretro,retroarch-assets,v$(RETROARCH_ASSETS_VERSION))
RETROARCH_ASSETS_LICENSE = CC-BY-4.0
RETROARCH_ASSETS_LICENSE_FILES = COPYING
RETROARCH_ASSETS_DEPENDENCIES = host-pkgconf

RETROARCH_ASSETS_INSTALL_DIR=$/usr/share/libretro/assets/

define RETROARCH_ASSETS_INSTALL_TARGET_CMDS
	mkdir -p $(TARGET_DIR)/$(RETROARCH_ASSETS_DESTDIR)
	DESTDIR=$(TARGET_DIR) INSALLDIR=$(RETROARCH_ASSETS_INSTALL_DIR) \
		$(MAKE) -C $(@D) install
endef

$(eval $(generic-package))
