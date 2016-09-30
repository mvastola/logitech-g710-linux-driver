KVERSION = $(shell uname -r)
KDIR := /lib/modules/$(KVERSION)/build
PWD := $(shell pwd)

obj-m = hid-lg-g710-plus.o

default: build

build:
	make -C $(KDIR) M=$(PWD) modules
clean:
	make -C $(KDIR) M=$(PWD) clean
install:
	make -C $(KDIR) M=$(PWD) modules_install
install-module-aliases:
	cp -fu $(PWD)/contrib/modprobe.d.conf /lib/modprobe.d/hid-lg-g710-plus.conf
	make -C $(PWD) reload-driver
unistall-module-aliases:
	rm -f /lib/modprobe.d/hid-lg-g710-plus.conf
reload-driver:
	$(PWD)/contrib/reload-g710-driver.sh
