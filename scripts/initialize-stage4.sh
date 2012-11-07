#!/usr/bin/env bash
#
# Copyright (C) 2012 FOSS-Group
#                    Germany
#                    http://www.foss-group.de
#                    support@foss-group.de
#
# Authors:
#  Tiziano Müller <tiziano.mueller@stepping-stone.ch>
#  
# Licensed under the EUPL, Version 1.1 or – as soon they
# will be approved by the European Commission - subsequent
# versions of the EUPL (the "Licence");
# You may not use this work except in compliance with the
# Licence.
# You may obtain a copy of the Licence at:
#
# http://www.osor.eu/eupl
#
# Unless required by applicable law or agreed to in
# writing, software distributed under the Licence is
# distributed on an "AS IS" basis,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either
# express or implied.
# See the Licence for the specific language governing
# permissions and limitations under the Licence.
#
#
#

runtimeRoot="/build/runtime-root"

if [ ! -d "${runtimeRoot}" ] ; then
	echo "ERROR: ${runtimeRoot} does not exist or is not a directory"
	exit 1
fi

# TODO: find a better way to deploy this configuration
echo "Writing /boot/grub/grub.conf..."
cat > "${runtimeRoot}/boot/grub/grub.conf" << EOF
# Boot automatically after 10 secs.
timeout 10

# By default, boot the first entry.
default 0

# Fallback to the second entry.
fallback 1

# splash image
splashimage=(hd0,0)/grub/foss-cloud-splash.xpm.gz

# For booting GNU/Linux
title FOSS-Cloud
root (hd0,0)
kernel /kernel root=/dev/ram0 init=/linuxrc ramdisk=8192 real_root=LABEL=OSBD_root video=vesafb:mtrr:3,ywrap vga=792
initrd /initramfs

# Fallback
title FOSS-Cloud (without framebuffer)
root (hd0,0)
kernel /kernel root=/dev/ram0 init=/linuxrc ramdisk=8192 real_root=LABEL=OSBD_root
initrd /initramfs
EOF

echo "Setting initial 'root' password"
echo "root:admin" | chroot "${runtimeRoot}" chpasswd

