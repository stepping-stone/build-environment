#!/usr/bin/env bash
#
# Copyright (C) 2013 FOSS-Group
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

for f in /var/portage/packages /var/lib/layman/foss-cloud /usr/portage ; do
	[ -d "${runtimeRoot}${f}" ] || mkdir -p "${runtimeRoot}${f}"
	mountpoint -q "${runtimeRoot}${f}" || mount --bind "${f}" "${runtimeRoot}/${f}"
	mountpoint -q "${runtimeRoot}${f}" && mount -o remount,ro "${runtimeRoot}/${f}"
done

mountpoint -q "${runtimeRoot}/proc" || mount -t proc none "${runtimeRoot}/proc"

exec chroot "${runtimeRoot}" rc-update $@
