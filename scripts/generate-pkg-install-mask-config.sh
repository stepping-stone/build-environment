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

configurationOverlay="/build/configuration-overlay"
fcConfigInstallMaskFile="/etc/portage/env/fc-configuration.conf"

echo "Generating list of configuration files from ${configurationOverlay}..."
files=$(find "${configurationOverlay}" -type f ! -path "*/.git/*" | sed -e "s|${configurationOverlay}|/etc|" | tr '\n' ' ')

echo "Writing ${fcConfigInstallMaskFile} ..."
mkdir -p "${fcConfigInstallMaskFile%/*}"
chmod 0755 "${fcConfigInstallMaskFile%/*}"
echo "INSTALL_MASK=\"$(tr '\n' ' ' <<< ${files})\"" > "${fcConfigInstallMaskFile}"
chmod 0644 "${fcConfigInstallMaskFile}"

echo "Writing /etc/portage/bashrc for the rest of the files ..."
cat > /etc/portage/bashrc << EOF

# When installing the FOSS-Cloud configuration we want to blank out
# everything from it when installing to the build-root to avoid file collisions
# with the real packages. And we want the packages to install their configuration files.
# On the other hand we don't want the configuration files ending up in the binary packages.

if [ "\${CATEGORY}/\${PN}" != "sys-apps/fc-configuration" ] ; then
        export PKG_INSTALL_MASK="${files}"
fi

EOF
chmod 0644 /etc/portage/bashrc

echo "Writing /etc/portage/package.env ..."
echo "sys-apps/fc-configuration fc-configuration.conf" > /etc/portage/package.env
chmod 0644 "${fcConfigInstallMaskFile}"

echo "Looking up packages you may have to re-install ..."
pkgs=$(/usr/bin/equery b ${files} | sort -u)
echo ""
echo "${pkgs}"
echo ""
echo "You may use the following commands to rebuild and reinstall them blindly:"
echo "  emerge -1va $(for p in ${pkgs} ; do echo -n "=${p} " ; done)"
echo ""
echo "  /build/scripts/emerge-runtime.sh -1va $(for p in ${pkgs} ; do echo -n "=${p} " ; done)"
echo ""