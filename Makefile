.DEFAULT: build
KVERSION = $(shell uname -r)
KDIR := /lib/modules/$(KVERSION)/build
PWD := $(shell pwd)
BUILD_PATH := $(abspath $(PWD)/$(BUILD_MODULE_LOCATION))

MODULE_INSTALL_DIR := $(abspath $(KDIR)/../$(DEST_MODULE_LOCATION)/dkms)
MODPROBE_INSTALL_DIR := /lib/modprobe.d

MODULE_NAME := $(if $(BUILT_MODULE_NAME), $(notdir $(PWD)))
OBJECT_FILE := $(MODULE_NAME).o
MODULE_FILE := $(OBJECT:.o=.ko)
MODPROBE_FILE := $(MODULE_NAME).conf

obj-m := $(OBJECT_FILE) # TODO: check if needed

build:
	make -C $(KDIR) M=$(PWD) modules_build

install:
	make -C $(KDIR) M=$(PWD) modules_install

clean:
	make -C $(KDIR) M=$(PWD) modules_clean

aliases_build:
	modinfo $(MODULE_INSTALL_DIR)/$(MODULE_FILE) &>/dev/null
	modinfo -0 -F alias $(MODULE_INSTALL_DIR)/$(MODULE_FILE) \|
		xargs -0 -r -n1 -i echo "alias {} $(MODULE_NAME)" > \
			$(BUILD_PATH)/$(MODPROBE_FILE)

aliases_install: aliases_build
	install -m 644 -t $(MODPROBE_INSTALL_DIR) $(BUILD_PATH)/$(MODPROBE_FILE)

aliases_clean:
	rm -f $(BUILD_PATH)/$(MODPROBE_FILE)

aliases_remove:
	rm -f $(MODPROBE_INSTALL_DIR)/$(MODPROBE_FILE)

reload:
	udevadm control -R
	modinfo -0 -F alias $(MODULE_INSTALL_DIR)/$(MODULE_FILE) | xargs -0 -r -n1 -i \
		udevadm trigger -v -t devices -c remove -p "HID_UNIQ=?MODALIAS={}"
	modinfo -0 -F alias $(MODULE_INSTALL_DIR)/$(MODULE_FILE) | xargs -0 -r -n1 -i \
		udevadm trigger -v -t devices -c remove -p "MODALIAS={}"
	rmmod -f $(MODULE_NAME)
	modprobe $(MODULE_NAME)
	touch /sys/bus/hid/drivers_probe
	udevadm control -R

post_install: 
	depmod -a
	make -C $(PWD) aliases_install
	make -C $(PWD) reload

post_remove: 
	make -C $(PWD) aliases_remove
	make -C $(PWD) reload

