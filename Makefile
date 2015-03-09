############################################################
# <bsn.cl fy=2013 v=none>
#
#        Copyright 2013, 2014 BigSwitch Networks, Inc.
#
#
#
# </bsn.cl>
############################################################
#
# ONL Loader
#
############################################################

#
# This system is designed to be built as a component
# in the ONL distribution.
#

ifndef ONL
$(error $$ONL is required to build the ONL Loader)
endif

#
# We build for these architectures
#
ARCHS := powerpc i386 x86_64
BUILDROOT_ARCHDIRS := $(foreach a,$(ARCHS),buildroot-$(a))

.PHONY: all clean setup $(BUILDROOT_ARCHDIRS)

all: setup $(BUILDROOT_ARCHDIRS)

clean:
	rm -rf $(BUILDROOT_ARCHDIRS)


#
# The subset of platforms that should be supported in this build
# should be specified with the ONL_LOADER_PLATFORM_INCLUDE_LIST variable.
#
# If this is unspecified, then all available platforms in the ONL platform-config
# components will be included.
#
# These platform-config settings are included as part of the initrd build and used
# by the ONL loader functionality to initialize a particular platform.
#
ifndef ONL_LOADER_PLATFORM_INCLUDE_LIST
ONL_LOADER_PLATFORM_INCLUDE_LIST := $(shell ls $(ONL)/components/all/platform-config)
endif

$(info Building with support for the following platforms: $(ONL_LOADER_PLATFORM_INCLUDE_LIST))

#
# The platform-config packages for each platform are ONL debian component packages.
#
# We make sure they are built for the selected platforms, then extract their contents
# into the overlay rootfiles used to create the initrd.
#
# Ideally these packages would just be installed directly when the initrd moves to a
# debian-based system.
#
platform-configs:
	rm -rf rootfiles/lib/platform-config
	$(foreach p,$(ONL_LOADER_PLATFORM_INCLUDE_LIST), $(ONL)/tools/onlpkg.py --build --extract rootfiles platform-config-$(p):all; )

setup: platform-configs
	cp $(wildcard patches/busybox*.patch) buildroot/package/busybox/
	cp $(wildcard patches/kexec*.patch) buildroot/package/kexec/
	sed -i 's%^DOSFSTOOLS_SITE =.*%DOSFSTOOLS_SITE = http://downloads.openwrt.org/sources%' buildroot/package/dosfstools/dosfstools.mk
	sed -i 's%^UEMACS_SITE =.*%UEMACS_SITE = http://www.kernel.org/pub/linux/kernel/uemacs%;s%^UEMACS_SOURCE =.*%UEMACS_SOURCE = em-$$(UEMACS_VERSION).tar.gz%' buildroot/package/uemacs/uemacs.mk
	mkdir -p buildroot/package/jq
	cp patches/jq.mk buildroot/package/jq/jq.mk
	cp patches/jq.Config.in buildroot/package/jq/Config.in
	sed -i '/[/]jq[/]/d' buildroot/package/Config.in
	sed -i '/[/]yajl[/]/a\source "package/jq/Config.in"' buildroot/package/Config.in
	mkdir -p $(BUILDROOT_ARCHDIRS)
	$(foreach a,$(ARCHS),cp buildroot.config-$(a) buildroot-$(a)/.config ;)


define buildroot_arch
buildroot-$(1):
	rm -fr buildroot-$(1)/rootfiles
	mkdir -p buildroot-$(1)/rootfiles/etc
	cp /dev/null buildroot-$(1)/rootfiles/etc/issue
ifdef VERSION_FILE
	cat $(VERSION_FILE) > buildroot-$(1)/rootfiles/etc/version.sh
endif
	make -C buildroot O=../buildroot-$(1)

buildroot-menuconfig-$(1):
	make -C buildroot menuconfig O=../buildroot-$(1)
	cp buildroot-powerpc/.config buildroot.config-$(1)
endef

$(foreach a,$(ARCHS),$(eval $(call buildroot_arch,$(a))))

busybox-menuconfig:
	make -C buildroot busybox-menuconfig O=../buildroot-powerpc
	cp buildroot-powerpc/build/busybox-*/.config busybox.config
