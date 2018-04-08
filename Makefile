.NOTPARALLEL:
.DEFAULT: build
KVERSION = $(shell uname -r)
KDIR := /lib/modules/$(KVERSION)/build
PWD := $(shell pwd)
BUILD_PATH := /lib/modules/$(KVERSION)/updates/dkms

MODPROBE_INSTALL_DIR := /lib/modprobe.d

MODULE_NAME ?= $(module)
OBJECT_FILE := $(MODULE_NAME).o
MODULE_FILE := $(OBJECT_FILE:.o=.ko)
MODPROBE_FILE := $(MODULE_NAME).conf

obj-m := $(OBJECT_FILE)

build:
	make -C $(KDIR) M=$(PWD) modules
	modinfo -0 -F alias $(BUILD_PATH)/$(MODULE_FILE) 2>&1 | \
		xargs -0 -r -n1 -i echo "alias {} $(MODULE_NAME)" > \
			$(PWD)/$(MODPROBE_FILE)

install:
	make -C $(KDIR) M=$(PWD) modules_install
	install -m 644 -t $(MODPROBE_INSTALL_DIR) $(PWD)/$(MODPROBE_FILE)

clean:
	make -C $(KDIR) M=$(PWD) clean
	rm -vf $(PWD)/$(MODPROBE_FILE)

uninstall: 
	rm -f $(MODPROBE_INSTALL_DIR)/$(MODPROBE_FILE)

remove_devs:
	udevadm control -R && udevadm settle
	modinfo -0 -F alias $(MODULE_NAME) 2>/dev/null | xargs -0 -r -n1 -i \
		udevadm trigger -v -t devices -c remove -p "HID_UNIQ=?MODALIAS={}"
	udevadm settle
	modinfo -0 -F alias $(MODULE_NAME) 2>/dev/null | xargs -0 -r -n1 -i \
		udevadm trigger -v -t devices -c remove -p "MODALIAS={}"
	udevadm settle
	sleep 10

probe_devs:
	touch /sys/bus/hid/drivers_probe
	udevadm control -R && udevadm settle

rmmod:
	!(lsmod | grep -qx $(MODULE_NAME) ) || rmmod -f $(MODULE_NAME)
#	udevadm control -R && udevadm settle

modprobe:
	modprobe -a $(MODULE_NAME)
#	udevadm control -R && udevadm settle
  
depmod:
	depmod -a $(KVERSION)

post_install: rmmod depmod remove_devs modprobe probe_devs

post_remove: uninstall rmmod remove_devs probe_devs

