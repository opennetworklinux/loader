############################################################
# <bsn.cl fy=2013 v=onl>
# 
#        Copyright 2013, 2014 BigSwitch Networks, Inc.        
# 
# Licensed under the Eclipse Public License, Version 1.0 (the
# "License"); you may not use this file except in compliance
# with the License. You may obtain a copy of the License at
# 
#        http://www.eclipse.org/legal/epl-v10.html
# 
# Unless required by applicable law or agreed to in writing,
# software distributed under the License is distributed on an
# "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND,
# either express or implied. See the License for the specific
# language governing permissions and limitations under the
# License.
# 
# </bsn.cl>
############################################################
#
# Open Network Linux Loader
#
############################################################

#
# This system is designed to be built as a component
# in the Open Network Linux distribution.
#

ifndef ONL
$(error $$ONL is required to build the Open Network Linux Loader)
endif

.PHONY: all clean setup buildroot-powerpc buildroot-menuconfig-powerpc buildroot-i386
.PHONY: buildroot-menuconfig-i386 busybox-menuconfig loader-quanta-lb9

all: setup buildroot-powerpc buildroot-i386

clean:
	rm -rf buildroot-powerpc buildroot-i386


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
	mkdir -p buildroot-powerpc buildroot-i386
	cp buildroot.config-powerpc buildroot-powerpc/.config
	cp buildroot.config-i386 buildroot-i386/.config
	make -C buildroot source O=../buildroot-powerpc


buildroot-powerpc:
	rm -fr buildroot-powerpc/rootfiles
	mkdir -p buildroot-powerpc/rootfiles/etc
	cp /dev/null buildroot-powerpc/rootfiles/etc/issue
	if test "$(ONL_RELEASE)"; then :; else echo "missing ONL_RELEASE"; exit 1; fi ;\
	echo "Open Network Linux Loader [$(ONL_RELEASE)]" >> buildroot-powerpc/rootfiles/etc/issue
	echo "" >> buildroot-powerpc/rootfiles/etc/issue
	make -C buildroot O=../buildroot-powerpc


buildroot-menuconfig-powerpc:
	make -C buildroot menuconfig O=../buildroot-powerpc
	cp buildroot-powerpc/.config buildroot.config-powerpc


buildroot-i386:
	rm -fr buildroot-i386/rootfiles
	mkdir -p buildroot-i386/rootfiles/etc
	cp /dev/null buildroot-i386/rootfiles/etc/issue
	if test "$(ONL_RELEASE)"; then :; else echo "missing ONL_RELEASE"; exit 1; fi ;\
	echo "Open Network Linux Loader [$(ONL_RELEASE)]" >> buildroot-i386/rootfiles/etc/issue
	echo "" >> buildroot-i386/rootfiles/etc/issue
	make -C buildroot O=../buildroot-i386


buildroot-menuconfig-i386:
	make -C buildroot menuconfig O=../buildroot-i386
	cp buildroot-i386/.config buildroot.config-i386


busybox-menuconfig:
	make -C buildroot busybox-menuconfig O=../buildroot-powerpc
	cp buildroot-powerpc/build/busybox-*/.config busybox.config
