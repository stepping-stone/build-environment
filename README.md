build-environment
=================

FOSS-Cloud build related scripts

Includes some simple and hack-ish scripts to unpack and rebuild the sysresccd.

unpack.sh
---------

unpacks a sysresccd-iso

requires:
* app-arch/libarchive
* >=sys-fs/squashfs-tools-4.2_pre20101231 with USE="xz xattr"

gen_squashfs.sh
---------------

regenerates the squash'ed root image (sysrcd.dat)

requires:
* >=sys-fs/squashfs-tools-4.2_pre20101231 with USE=xz

gen_iso.sh
----------

generates the final iso

requires:
* app-cdr/cdrtools with USE="unicode"

