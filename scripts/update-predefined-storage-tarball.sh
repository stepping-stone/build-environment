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

TARBALL_PATH="${runtimeRoot}/usr/share/foss-cloud/predefined-storage.tar.bz2"
DEFAULT_GID="3000"
DEFAULT_DIR_PERMS="2770"
VIRTIO_ISO_SRC="/var/portage/distfiles/virtio-win-0.1-52.iso"
DESTINATION_BASEDIR="/var/virtualization"
VIRTIO_ISO_DEST="${DESTINATION_BASEDIR}/iso/85d7e9f5-4288-4a3f-b209-c12ff11c61f3.iso"
VIRTIO_ISO_PERMS="0644"
DIRS="${DESTINATION_BASEDIR}/iso ${DESTINATION_BASEDIR}/iso-choosable ${DESTINATION_BASEDIR}/vm-dynamic ${DESTINATION_BASEDIR}/vm-persistent ${DESTINATION_BASEDIR}/vm-templates"

TEMPDIR="$(mktemp -d)"

echo "building new predefined storage tarball in '${TEMPDIR}'"

for dir in ${DIRS} ; do
    echo "creating base-directory '${dir}'"
    mkdir -p "${TEMPDIR}/${dir}"
done

for xml in "${osbdRuntimeRoot}"/etc/libvirt/storage/*.xml ; do
    path=$(xmllint --xpath '//pool/target/path/text()' "${xml}")
    echo "adding storage pool '${path}'"
    mkdir -p "${TEMPDIR}/${path}"
done

if [ ! -e "${VIRTIO_ISO_SRC}" ] ; then
    echo "'${VIRTIO_ISO_SRC}' could not be found. Trying to fetch..."
    wget -O "${VIRTIO_ISO_SRC}" "http://alt.fedoraproject.org/pub/alt/virtio-win/latest/images/bin/$(basename ${VIRTIO_ISO_SRC})" || exit 1
fi

echo "copying virtio iso image from '${VIRTIO_ISO_SRC}' to '${TEMPDIR}/${VIRTIO_ISO_DEST}'"
cp "${VIRTIO_ISO_SRC}" "${TEMPDIR}/${VIRTIO_ISO_DEST}"

echo "setting permissions"
chgrp -R ${DEFAULT_GID} "${TEMPDIR}"
chmod -R ${DEFAULT_DIR_PERMS} "${TEMPDIR}"
chmod ${VIRTIO_ISO_PERMS} "${TEMPDIR}/${VIRTIO_ISO_DEST}"

echo "rolling tarball '${TARBALL_PATH}'"
mkdir -p "${TARBALL_PATH%/*}"
tar cvjf "${TARBALL_PATH}" -C "${TEMPDIR}${DESTINATION_BASEDIR}" ./

rm -rf "${TEMPDIR}"

