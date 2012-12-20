#!/bin/sh
#
# Written by Steve Jardine @ CDM Data
# 11/20/2012
#
# This script is for loading CDM Data iTAB systems
# with eMMC.

# This script relies on two things:
#
# 1.There is a second partition on the SD card where
# this script is contained
#
# 2.The first partiton has the kernel and modules, initrd, 
#	uramdisk.img, a boot script for eMMC, and a boot script
#	the SD card (busybox)
#
#
#
#	Create working directories

mkdir e1
mkdir 1
mkdir 2

#	Partition and format 16 Gb eMMC

DRIVE=/dev/mmcblk1
echo "Deleting partitions...";
dd if=/dev/zero of=$DRIVE count=100 bs=512
echo "Deleting partitions...Done";
echo "Creating New partitions...";
fdisk $DRIVE << EOF
n
p
1

+225M

n
p
2

+806M
n
e
3

+1023M
n
l

+400M
n
l

+400M
n
l

+200M
n
p
4


n



t
1
b
t
7
b
t
4
b

w	
EOF
echo "Creating New partitions...Done";
echo "Formating partitions...";

mkdosfs -n BOOT ${DRIVE}p1
mkfs.ext4 -L SYSTEM ${DRIVE}p2
mkfs.ext4 -L CACHE ${DRIVE}p6
mkfs.ext4 -L DATA ${DRIVE}p5
mkdosfs -n RECOVERY ${DRIVE}p7
mkdosfs -F 32 -n MEDIA ${DRIVE}p4

#	Mount working partitions + eMMC boot partition
#	Write boot tarball to eMMC boot part

mount /dev/mmcblk0p2 /mnt/1
mount -t vfat /dev/mmcblk0p1 /mnt/2
mount -t vfat /dev/mmcblk1p1 /mnt/e1
cd /mnt/e1/
tar -xvf /mnt/1/boot.tar 
cd -
umount /mnt/e1

echo "Boot partition updated...";

# 	Mount eMMC system partition
#	Write system tarball to eMMC system part

mount /dev/mmcblk1p2 /mnt/e1
cd /mnt/e1
tar -xvf /mnt/1/system.tar
cd /root
umount /mnt/e1

echo "Added system...";

# 	Mount eMMC data partition
#	Write data tarball to eMMC data part

mount /dev/mmcblk1p5 /mnt/e1
cd /mnt/e1
tar -xvf /mnt/1/data.tar
cd /root
umount /mnt/e1

# 	Mount eMMC recovery partition
#	Write recovery tarball to eMMC recovery part

mount /dev/mmcblk1p7 /mnt/e1
cd /mnt/e1
tar -xvf /mnt/1/recovery.tar
cd /root
umount /mnt/e1

# 	Clean up working directories

umount /mnt/1
rm -rf /mnt/e1
rm -rf /mnt/1

#	Swap eMMC boot script for master boot script. Will boot to eMMC 
#	after reboot command.

#cp /mnt/2/nitrogen53_bootscript /mnt/2/nitrogen53_bootscript_sd
cp /mnt/2/nitrogen53_bootscript_emmc /mnt/2/nitrogen53_bootscript
reboot


