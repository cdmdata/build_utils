#!/bin/sh
DRIVE=$1
for n in ${DRIVE}* ; do umount $n ; done
echo "About to delete from $@....";
read -r -p "Are you sure you? [Y/n] " response
if [[ $response =~ ^([yY][eE][sS]|[yY])$ ]] 
then
echo "Deleting partitions...";
sudo dd if=/dev/zero of=$DRIVE count=100 bs=512
echo "Deleting partitions...Done";
echo "Creating New partitions...";
sudo fdisk $DRIVE << EOF
n
p
1
1
+21M

n
p
2

+260M
n
e
3

+1680M
n
l

+1100M
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
echo "Creating New partitions...Done";
echo "Formating partitions...";

sudo mkfs.vfat -n BOOT ${DRIVE}1
sudo mkfs.ext4 -L SYSTEM ${DRIVE}2
sudo mkfs.ext4 -L CACHE ${DRIVE}5
sudo mkfs.ext4 -L DATA ${DRIVE}6
sudo mkfs.vfat -n RECOVERY ${DRIVE}7
sudo mkfs.vfat -F 32 -n MEDIA ${DRIVE}4

echo "Formating partitions...Done";
echo "Drive Mount...";
sudo mkdir /media/BOOT
sudo mkdir /media/SYSTEM
sudo mkdir /media/CACHE
sudo mkdir /media/DATA
sudo mkdir /media/RECOVERY
sudo mkdir /media/MEDIA

sudo mount ${DRIVE}1 /media/BOOT
sudo mount ${DRIVE}2 /media/SYSTEM
sudo mount ${DRIVE}5 /media/CACHE
sudo mount ${DRIVE}6 /media/DATA
sudo mount ${DRIVE}7 /media/RECOVERY
sudo mount ${DRIVE}4 /media/MEDIA
echo "Drive Mount...Done";

echo "Copy SYSTEM ...";
sudo cp -ravf ../out/target/product/imx53_nitrogenk/system/* /media/SYSTEM/
####sudo cp -ravf ../root/* /media/ROOT/
echo "Copy DATA ...";
sudo cp -ravf ../out/target/product/imx53_nitrogenk/data/* /media/DATA/
echo "Copy RECOVERY ...";
sudo cp -ravf ../out/target/product/imx53_nitrogenk/recovery/* /media/RECOVERY/
echo "Copy KERNEL ...";
sudo mkimage -A arm -O linux -T ramdisk -n "Initial Ram Disk" -d ../out/target/product/imx53_nitrogenk/ramdisk.img ../out/target/product/imx53_nitrogenk/initrd.u-boot
sudo cp ../out/target/product/imx53_nitrogenk/initrd.u-boot /media/BOOT
sudo cp ../nitrogen53_bootscript /media/BOOT

sudo cp ../kernel_imx/arch/arm/boot/uImage /media/BOOT/uImage53
sudo mkdir /media/BOOT/lib/
sudo mkdir /media/BOOT/lib/modules/
sudo cp -ravf ../kernel_imx/drivers/media/video/mxc/capture/*.ko /media/BOOT/lib/modules/
sudo cp -ravf ../kernel_imx/drivers/i2c/xrp6840.ko /media/BOOT/lib/modules/

#echo "Copy wireless drivers"
sudo cp -ravf ../compat-wireless-2011-08-08/drivers/net/wireless/wl12xx/wl12xx.ko /media/BOOT/lib/modules/
sudo cp -ravf ../compat-wireless-2011-08-08/drivers/net/wireless/wl12xx/wl12xx_sdio.ko /media/BOOT/lib/modules/
sudo cp -ravf ../compat-wireless-2011-08-08/net/mac80211/mac80211.ko /media/BOOT/lib/modules/
sudo cp -ravf ../compat-wireless-2011-08-08/net/wireless/cfg80211.ko /media/BOOT/lib/modules/
sudo cp -ravf ../compat-wireless-2011-08-08/compat/compat.ko /media/BOOT/lib/modules/
cd ..
sudo sync
echo "done"

echo "set permissions"
sudo chmod 777 -R /media/BOOT/
sudo chmod 777 -R /media/SYSTEM/
sudo chmod 777 -R /media/CACHE/
sudo chmod 777 -R /media/DATA/
sudo chmod 777 -R /media/RECOVERY/
sudo chmod 777 -R /media/MEDIA/
echo "set permissions...Done"
echo "Umount..."
sudo umount /media/BOOT
sudo umount /media/SYSTEM
sudo umount /media/CACHE
sudo umount /media/DATA
sudo umount /media/RECOVERY
sudo umount /media/MEDIA
for n in ${DRIVE}* ; do umount $n ; done
echo "Umount...Done"
echo "Remove Folder..."
sudo rm -rf /media/SYSTEM/*
sudo rm -rf /media/DATA/*
sudo rm -rf /media/RECOVERY/*
sudo rm -rf /media/CACHE/*

sudo rmdir -v /media/BOOT
sudo rmdir -v /media/SYSTEM
sudo rmdir -v /media/CACHE
sudo rmdir -v /media/DATA
sudo rmdir -v /media/RECOVERY
sudo rmdir -v /media/MEDIA
echo "Remove Folder...Done"
fi


