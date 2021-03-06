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

buildRoot="/build"
sysresccdRoot="${buildRoot}/sysresccd"

if [ ${UID} != 0 ] ; then
    echo "You have to be superuser"
    exit 1
fi

rm -f "${sysresccdRoot}/customcd/isoroot/sysrcd.dat"

mksquashfs \
    "${sysresccdRoot}/customcd/files/" \
    "${sysresccdRoot}/customcd/isoroot/sysrcd.dat" \
    -comp xz 

# Create the MD5 hash for the SquashFS file

cd "${sysresccdRoot}/customcd/isoroot"

md5sum \
    "sysrcd.dat" > \
    "sysrcd.md5"

cd - > /dev/null
