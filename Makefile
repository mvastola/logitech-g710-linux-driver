.DEFAULT: all
.PHONY: all
PACKAGE_NAME = hid-lg-g710-plus
PACKAGE_VERSION = 0.1.1

KVERSION ?= $(shell uname -r)
KDIR := /lib/modules/$(KVERSION)/build
PWD := $(shell pwd)
BUILD_PATH := /lib/modules/$(KVERSION)/updates/dkms
PACKAGE = $(PACKAGE_NAME)-$(PACKAGE_VERSION)
DKMS_MODULES_NAME = $(PACKAGE_NAME)
DKMS_MODULES = $(DKMS_MODULES_NAME)/$(PACKAGE_VERSION)

MODPROBE_INSTALL_DIR := /lib/modprobe.d

OBJECT_FILE 	= $(DKMS_MODULES_NAME).o
MODULE_FILE 	= $(DKMS_MODULES_NAME).ko
MODPROBE_FILE = $(DKMS_MODULES_NAME).conf

obj-m += $(OBJECT_FILE)


modules modules_install clean: 
	$(MAKE) -C $(KDIR) M=$(PWD) $@

modules_uninstall: 
	rm -vf $(BUILD_PATH)/$(MODULE_FILE)

$(MODPROBE_FILE): modules
	modinfo -0 -F alias $(MODULE_FILE) | xargs -0 -n1 -i echo "alias {} $(DKMS_MODULES_NAME)" > $(MODPROBE_FILE)

files_install: $(MODPROBE_FILE)
	install -m 644 -t $(MODPROBE_INSTALL_DIR) $(PWD)/$(MODPROBE_FILE)
	depmod -a

files_uninstall:
	rm -vf $(MODPROBE_INSTALL_DIR)/$(MODPROBE_FILE)
	depmod -a
	udevadm control --reload

activate: modules_install files_install
	modprobe hid-lg-g710-plus
	udevadm control --reload
	$(PWD)/contrib/reload-g710-driver.sh
	udevadm control --reload

deactivate: files_uninstall
	rmmod -f  hid-lg-g710-plus || true
	touch /sys/bus/hid/drivers_probe
	udevadm control --reload

install: modules_install files_install 

uninstall: modules_uninstall files_uninstall deactivate

dkms_install: 
	dkms add .
	dkms build $(DKMS_MODULES)
	dkms install $(DKMS_MODULES)

dkms_uninstall: 
	dkms remove $(DKMS_MODULES) --all

