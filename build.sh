#!/bin/sh
# Ersoy Kardesler Linux build script
# Copyright (C) 2016-2021 John Davidson
#               2021-2022 Erdem Ersoy and Ercan Ersoy
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.


# Set script parameters
set -ex


# Linux-libre Package
LINUX_LIBRE_VERSION_NOT_GNU=5.10.100
LINUX_LIBRE_VERSION=${LINUX_LIBRE_VERSION_NOT_GNU}-gnu1
LINUX_LIBRE_NAME_AND_VERSION=linux-libre-${LINUX_LIBRE_VERSION}
LINUX_LIBRE_NAME_AND_VERSION_NOT_LIBRE_AND_GNU=linux-${LINUX_LIBRE_VERSION_NOT_GNU}
LINUX_LIBRE_PACKAGE_NAME=${LINUX_LIBRE_NAME_AND_VERSION}.tar.xz
LINUX_LIBRE_PACKAGE_NAME_NOT_LIBRE_AND_GNU=${LINUX_LIBRE_NAME_AND_VERSION_NOT_LIBRE_AND_GNU}.tar.xz
LINUX_LIBRE_PACKAGE_LOCATION=http://linux-libre.fsfla.org/pub/linux-libre/releases/${LINUX_LIBRE_VERSION}/${LINUX_LIBRE_PACKAGE_NAME}


# Busybox Package
BUSYBOX_VERSION=1.34.1
BUSYBOX_NAME_AND_VERSION=busybox-${BUSYBOX_VERSION}
BUSYBOX_PACKAGE_NAME=${BUSYBOX_NAME_AND_VERSION}.tar.bz2
BUSYBOX_PACKAGE_LOCATION=https://busybox.net/downloads/${BUSYBOX_PACKAGE_NAME}


# Syslinux Package
SYSLINUX_VERSION=6.03
SYSLINUX_NAME_AND_VERSION=syslinux-${SYSLINUX_VERSION}
SYSLINUX_PACKAGE_NAME=${SYSLINUX_NAME_AND_VERSION}.tar.xz
SYSLINUX_PACKAGE_LOCATION=http://mirrors.edge.kernel.org/pub/linux/utils/boot/syslinux/${SYSLINUX_PACKAGE_NAME}


# Make build directories
mkdir -p packages
mkdir -p packages_extracted
mkdir -p rootfs
mkdir -p isoimage


# Download packages
cd packages

wget -nc ${LINUX_LIBRE_PACKAGE_LOCATION}
wget -nc ${BUSYBOX_PACKAGE_LOCATION}
wget -nc ${SYSLINUX_PACKAGE_LOCATION}

cd ..


# Extract packages
cd packages_extracted

if [ ! -d ${LINUX_LIBRE_NAME_AND_VERSION_NOT_LIBRE_AND_GNU} ]; then tar -xvf ../packages/${LINUX_LIBRE_PACKAGE_NAME} -C .; fi
if [ ! -d ${BUSYBOX_NAME_AND_VERSION} ]; then tar -xvf ../packages/${BUSYBOX_PACKAGE_NAME} -C .; fi
if [ ! -d ${SYSLINUX_NAME_AND_VERSION} ]; then tar -xvf ../packages/${SYSLINUX_PACKAGE_NAME} -C .; fi

cd ..


# Configure and install Linux
cd packages_extracted/${LINUX_LIBRE_NAME_AND_VERSION_NOT_LIBRE_AND_GNU}

make distclean x86_64_defconfig

cp -T ../../configs/linux-config .config

make savedefconfig bzImage

cp arch/x86/boot/bzImage ../../isoimage/kernel.gz

cd ../..


# Configure and install BusyBox
cd packages_extracted/${BUSYBOX_NAME_AND_VERSION}

make distclean defconfig

cp -T ../../configs/busybox-config .config

make busybox install

cp -r _install/* ../../rootfs

cd ../..


# Prepare root filesystem with some changes
cd rootfs

mkdir dev sys tmp
mkdir -p etc/init.d
mkdir -p proc/sys/kernel

## Add /etc/group
echo 'root:x:0:' > etc/group
echo 'daemon:x:1:' >> etc/group

## Add /etc/inittab
echo '::sysinit:/etc/init.d/rcS' > etc/inittab
echo '::respawn:/sbin/syslogd -n' >> etc/inittab
echo '::respawn:/sbin/klogd -n' >> etc/inittab
echo '::respawn:/sbin/getty 115200 console' >> etc/inittab

## Add /etc/init.d/rcS
echo '#!/bin/sh' > etc/init.d/rcS
echo 'dmesg -n 1' >> etc/init.d/rcS
echo 'mount -t proc proc /proc' >> etc/init.d/rcS
echo 'mount -t sysfs sysfs /sys' >> etc/init.d/rcS
echo 'mount -t tmpfs -o size=64m tmp_files /tmp' >> etc/init.d/rcS
echo 'ln -s /tmp /var/cache' >> etc/init.d/rcS
echo 'ln -s /tmp /var/lock' >> etc/init.d/rcS
echo 'ln -s /tmp /var/log' >> etc/init.d/rcS
echo 'ln -s /tmp /var/run' >> etc/init.d/rcS
echo 'ln -s /tmp /var/spool' >> etc/init.d/rcS
echo 'ln -s /tmp /var/tmp' >> etc/init.d/rcS
echo 'mount -t devtmpfs devtmpfs /dev' >> etc/init.d/rcS
echo 'echo /sbin/mdev > /proc/sys/kernel/hotplug' >> etc/init.d/rcS
echo 'mdev -s' >> etc/init.d/rcS

chmod +x etc/init.d/rcS

## Add /etc/mdev.conf
echo 'null root:root 666' > etc/mdev.conf
echo 'random root:root 444' >> etc/mdev.conf
echo 'urandom root:root 444' >> etc/mdev.conf

## Add /etc/motd
echo '*********************************' > etc/motd
echo '*                               *' >> etc/motd
echo '* Welcome to Ersoy Kardesler OS *' >> etc/motd
echo '*                               *' >> etc/motd
echo '*********************************' >> etc/motd

## Add /etc/passwd
echo 'root:x:0:0:root:/root:/bin/sh' > etc/passwd
echo 'daemon:x:1:1:daemon:/usr/sbin:/bin/false' >> etc/passwd 

## Add /etc/profile
echo '#!/bin/sh' > etc/profile

chmod +x etc/profile

## Add /etc/shadow
echo 'root::10933:0:99999:7:::' > etc/shadow
echo 'daemon:*:10933:0:99999:7:::' >> etc/shadow

chmod 0600 etc/shadow

# Package root filesystem and copy root filesystem to ISO filesystem

find ./* | cpio -R root:root -H newc -o | gzip > ../isoimage/rootfs.gz

cd ..


# Copy ISOLINUX files to ISO filesystem and Make ISOcd 
cd packages_extracted/${SYSLINUX_NAME_AND_VERSION}

cp bios/core/isolinux.bin ../../isoimage
cp bios/com32/elflink/ldlinux/ldlinux.c32 ../../isoimage

echo 'default kernel.gz initrd=rootfs.gz rdinit=/sbin/init console=tty0 vga=ask' > ../../isoimage/isolinux.cfg

xorriso -as mkisofs -o ../../ersoy_kardesler.iso -b isolinux.bin -c boot.cat -no-emul-boot -boot-load-size 20 -boot-info-table ../../isoimage

cd ../..


# Re-set script parameters
set +ex
