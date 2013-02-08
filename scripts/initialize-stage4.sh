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

mkdir -p "${runtimeRoot}/boot/grub"
chmod 0755 "${runtimeRoot}"/boot{,/grub}

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

echo "Creating marker file for the installer to find the correct root partition..."
cat > "${runtimeRoot}/boot/osbd-boot-partition.txt" << EOF
Don't remove me!

This is required for grub to detect the boot partition
during the setup phase.
EOF
chmod 0644 "${runtimeRoot}/boot/osbd-boot-partition.txt"

echo "Setting initial 'root' password"
echo "root:admin" | chroot "${runtimeRoot}" chpasswd

echo "Creating network device symlinks"
ln -sf net.lo "${runtimeRoot}/etc/init.d/net.eth0"
ln -sf net.lo "${runtimeRoot}/etc/init.d/net.vmbr0"

echo "Registering services in the boot runlevel..."
for s in lvm ; do
    chroot "${runtimeRoot}" rc-update add "${s}" boot
done

echo "Registering services in the default runlevel..."
for s in dcron net.eth0 ntp-client ntpd sshd syslog-ng ; do
    chroot "${runtimeRoot}" rc-update add "${s}" default
done


echo "Registering initial crontab..."
chroot "${runtimeRoot}" crontab /etc/crontab

echo "Create temp directories for apache/php..."
mkdir -p "${runtimeRoot}"/var/tmp/apache2-php5/{sessions,soap,uploads}
chmod -R 0770 "${runtimeRoot}/var/tmp/apache2-php5"
chroot "${runtimeRoot}" chown -R apache\: /var/tmp/apache2-php5

echo "Create service users and groups..."
chroot "${runtimeRoot}" groupadd -g 3000 -r vm-storage
chroot "${runtimeRoot}" groupadd -g 110 -r qemu
chroot "${runtimeRoot}" useradd -c "QEMU system user" -u 107 -g qemu -G vm-storage,kvm -d /dev/null -s /bin/false -M -N qemu
chroot "${runtimeRoot}" gpasswd -a apache vm-storage
chroot "${runtimeRoot}" groupadd -g 53 -r pdns
chroot "${runtimeRoot}" useradd -c "PowerDNS recursor user" -u 53 -g pdns -d /dev/null -s /bin/false -M -N pdns

echo "Set /etc/mtab as a symlink to /proc/mounts..."
ln -sf /proc/mounts "${runtimeRoot}/etc/mtab"

initializeEmptyGitRepo() {
    local repoDir=$1
    local absRepoDir="${runtimeRoot}${repoDir}"
    local repoURI=$2
    local repoBranch=$3

    echo "Initializing ${repoDir} as an empty Git repository using branch ${repoBranch}..."
    mkdir -p "${absRepoDir}"
    mountpoint -q "${absRepoDir}" && umount "${absRepoDir}"
    pushd "${absRepoDir}" >/dev/null
    rm -rf .git
    git init
    git commit --allow-empty -m "empty commit to initialize master"
    git remote add -t "${repoBranch}" origin "${repoURI}"
    if [ "${repoBranch}" != "master" ] ; then
        git checkout -b "${repoBranch}"
    fi
    cat >> "${absRepoDir}/.git/config" << EOF
[branch "${repoBranch}"]
	remote = origin
	merge = refs/heads/${repoBranch}
EOF
    popd >/dev/null
    chroot "${runtimeRoot}" chown -R portage\: "${repoDir}"
}

# this should either point to stable branch (1.0/1.2/1.4/...)
# or "master" if this is the development version.
# A pre-branch is only valid in the RC-series where there is no stable branch yet.
FC_BRANCH="1.2-pre"
FC_PORTAGE_OVERLAY_URI="https://github.com/FOSS-Cloud/portage-overlay.git"

initializeEmptyGitRepo "/usr/portage" "https://github.com/FOSS-Cloud/portage.git" "${FC_BRANCH}"
initializeEmptyGitRepo "/var/lib/layman/foss-cloud" "${FC_PORTAGE_OVERLAY_URI}" "${FC_BRANCH}"

cat > "${runtimeRoot}/var/lib/layman/make.conf" << EOF
PORTDIR_OVERLAY="
/var/lib/layman/foss-cloud
\$PORTDIR_OVERLAY
"
EOF
chmod 0644 "${runtimeRoot}/var/lib/layman/make.conf"

overlaysSource="${runtimeRoot}/etc/layman/overlays/foss-cloud.xml"

if [ ! -f "${overlaysSource}" ] ; then
    echo "WARNING: ${overlaysSource} does not exist, falling back to ${overlaysSource##${runtimeRoot}}"
    overlaysSource="${overlaysSource##${runtimeRoot}}"
fi

cp -a "${overlaysSource}" "${runtimeRoot}/var/lib/layman/installed.xml"

echo "Cleanup the layman cache, rebuild and copy it..."
rm /var/lib/layman/cache_* "${runtimeRoot}/var/lib/layman"/cache_*
/usr/bin/layman -f
cp -a /var/lib/layman/cache_* "${runtimeRoot}/var/lib/layman"/

