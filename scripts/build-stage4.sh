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
stage4TarPath="/build/foss-cloud-stage4.tar"

echo "Unmounting possibly mounted bind mounts (and proc) ..."

mountpoint -q "${runtimeRoot}/proc" && umount "${runtimeRoot}/proc"

for f in /var/portage/packages /var/lib/layman/foss-cloud /usr/portage ; do
    mountpoint -q "${runtimeRoot}${f}" && umount "${runtimeRoot}/${f}"
done

# not yet configured
#chroot "${runtimeRoot}" localepurge

echo "Creating tarball ${stage4TarPath}..."
tar -cpf "${stage4TarPath}" -C "${runtimeRoot}" \
    --exclude=./var/log/emerge.log \
    --exclude=./var/cache/edb/* \
    --exclude=./etc/config-archive/* \
    .

