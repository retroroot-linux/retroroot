################################################################################
#
# retroroot-initrd
#
################################################################################

define RETROROOT_INITRD_INSTALL_TARGET_CMDS
	mkdir -p $(TARGET_DIR)/boot
	$(INSTALL) -m 0755 -D build/output/initrd/bzImage $(TARGET_DIR)/boot/bzImage
endef

$(eval $(generic-package))
