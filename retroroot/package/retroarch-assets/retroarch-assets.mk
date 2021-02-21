################################################################################
#
# retroarch-assets
#
################################################################################

RETROARCH_ASSETS_VERSION = 22a34b0b52f5dffdc38e90528b20457660d4a515
RETROARCH_ASSETS_SITE = https://github.com/libretro/retroarch-assets.git
RETROARCH_ASSETS_SITE_METHOD = git
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
