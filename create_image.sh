#!/bin/sh
SIZE=$1
IMAGEPATH=$2

SIZE_BYTES=0

if [ "$SIZE" == "" ]; then
	SIZE="4GB"
fi

if [ "$SIZE" == "4GB" ]; then
	echo "Creatig 4GB image file..."
	SIZE_BYTES=4008706048
fi

if [ "$SIZE" == "8GB" ]; then
	echo "Creatig 8GB image file..."
	SIZE_BYTES=7948206080
fi

if [ "$SIZE" == "32GB" ]; then
	echo "Creatig 32GB image file..."
	SIZE_BYTES=31914983424
fi

#7948206080
#31914983424
#3670016000

if [ "$IMAGEPATH" == "" ]; then
	echo "You must pass destination of the image file as a parameter to this script!."
	return
fi

LOOPDEVICE=`sudo losetup -f`

if [ "$LOOPDEVICE" != "/dev/loop0" ]; then
	echo "Loopdevice /dev/loop0 not available. This script will only work if loop0 is free!"
	return
fi

NOW=$(date +"%m-%d-%Y-%H%M%S")
DEST=$IMAGEPATH/$NOW-$SIZE.img


echo "MAKE SURE Android build/envsetup.sh has been run in this terminal and that you are running it from the root of the source tree!"
echo "Creating system image $DEST"
read -r -p "Are you sure you? [Y/n] " response
if [[ $response =~ ^([yY][eE][sS]|[yY])$ ]] 
then
echo "Create image file..."
qemu-img create -f raw $DEST $SIZE_BYTES
echo "Done"
echo ""

echo "Mounting image on /dev/loop0"
sudo losetup /dev/loop0 $DEST
sleep 3

echo "Creating New partitions on /dev/loop0..."
sudo fdisk /dev/loop0 << EOF
n
p
1
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

+50M
n
l

+500M
n
l

+16M
n
p
4


w	
EOF
echo "Done"
echo ""


echo "Unmounting /dev/loop0"
sudo losetup -d /dev/loop0
echo "Done"
echo ""

sleep 3

echo "Using kpartx to map image..."
sudo kpartx -a -v $DEST
echo "Done"
echo ""

ls /dev/mapper/

echo "Formating partitions..."
sudo mkfs.vfat -n BOOT /dev/mapper/loop0p1
sudo mkfs.ext4 -L SYSTEM /dev/mapper/loop0p2
sudo mkfs.vfat -F 32 -n MEDIA /dev/mapper/loop0p4
sudo mkfs.ext4 -L DATA /dev/mapper/loop0p5
sudo mkfs.vfat -n RECOVERY /dev/mapper/loop0p6
sudo mkfs.ext4 -L CACHE /dev/mapper/loop0p7

echo "Done"
echo ""

echo "Mounting partitions..."
sudo mkdir /media/BOOT
sudo mkdir /media/SYSTEM
sudo mkdir /media/CACHE
sudo mkdir /media/DATA
sudo mkdir /media/MEDIA

sudo mount /dev/mapper/loop0p1 /media/BOOT
sudo mount /dev/mapper/loop0p2 /media/SYSTEM
sudo mount /dev/mapper/loop0p5 /media/DATA
sudo mount /dev/mapper/loop0p7 /media/CACHE
sudo mount /dev/mapper/loop0p4 /media/MEDIA
echo "Done"
echo ""

echo "Copying files..."

croot
cd kernel_imx
sudo mkdir /media/BOOT/lib
sudo mkdir /media/BOOT/lib/modules
sudo cp arch/arm/boot/uImage /media/BOOT/uImage53
sudo cp -rvf drivers/media/video/mxc/capture/*.ko /media/BOOT/lib/modules/
sudo cp -rvf drivers/i2c/xrp6840.ko /media/BOOT/lib/modules/
sudo touch /media/BOOT/.bcb

croot
sudo cp -v bootable/bootloader/uboot-imx/board/boundary/nitrogen53/nitrogen53_bootscript_hdmi_recovery_partition /media/BOOT/nitrogen53_bootscript

cd out/target/product/imx53_nitrogenk
sudo cp -ravf system/* /media/SYSTEM/
sudo cp -ravf data/* /media/DATA/

mkimage -A arm -O linux -T ramdisk -n "Initial Ram Disk" -d ramdisk.img initrd.u-boot
sudo cp initrd.u-boot /media/BOOT/

#make recovery ramdisk
cp system/bin/busybox recovery/root/system/bin
cd recovery/root/
find . -print |cpio -H newc -o |gzip -9 > ../../recovery.ramdisk.cpio.gz
mkimage -A arm -O linux -T ramdisk -n "Recovery Ram Disk" -d ../../recovery.ramdisk.cpio.gz ../../initrd_recovery.u-boot
cd ../..
sudo cp initrd_recovery.u-boot /media/BOOT/

croot
sudo cp ../compat-wireless-2011-08-08/drivers/net/wireless/wl12xx/wl12xx.ko /media/BOOT/lib/modules/
sudo cp ../compat-wireless-2011-08-08/drivers/net/wireless/wl12xx/wl12xx_sdio.ko /media/BOOT/lib/modules/
sudo cp ../compat-wireless-2011-08-08/net/mac80211/mac80211.ko /media/BOOT/lib/modules/
sudo cp ../compat-wireless-2011-08-08/net/wireless/cfg80211.ko /media/BOOT/lib/modules/
sudo cp ../compat-wireless-2011-08-08/compat/compat.ko /media/BOOT/lib/modules/

cd ~/Development/cdm_nitrogen

sudo chmod 777 -R /media/SYSTEM/
sudo chmod 777 -R /media/DATA/
sudo chmod 777 -R /media/MEDIA/
sudo chmod 777 -R /media/CACHE/

echo "Running sync..."
sync

echo "Done"
echo ""

echo "Unmounting partitions..."
sudo umount /media/BOOT 
sudo umount /media/SYSTEM
sudo umount /media/CACHE
sudo umount /media/DATA
sudo umount /media/MEDIA

sudo rmdir /media/BOOT 
sudo rmdir /media/SYSTEM
sudo rmdir /media/CACHE
sudo rmdir /media/DATA
sudo rmdir /media/MEDIA
echo "Done"
echo ""

sleep 5

echo "Removing loop device..."
sudo sudo kpartx -d -v $DEST
echo "Done"
echo ""

echo "Cleaning up after kpartx..."
sudo dmsetup remove_all
sudo losetup -d /dev/loop0
echo "Done"
echo ""


echo "All Done!"
echo ""


fi