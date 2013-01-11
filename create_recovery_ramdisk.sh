echo "MAKE SURE Android build/envsetup.sh has been run in this terminal and that you are running it from the root of the source tree!"
echo "Create recovery ramdisk?"
read -r -p "Are you sure you? [Y/n] " response
if [[ $response =~ ^([yY][eE][sS]|[yY])$ ]] 
then
croot
echo "Copy files into recovery root..."
cp out/target/product/imx53_nitrogenk/system/bin/busybox out/target/product/imx53_nitrogenk/recovery/root/system/bin/
cp out/target/product/imx53_nitrogenk/system/bin/recovery out/target/product/imx53_nitrogenk/recovery/root/sbin/
cd out/target/product/imx53_nitrogenk/recovery/root
find . -print |cpio -H newc -o |gzip -9 > ../../recovery.ramdisk.cpio.gz
mkimage -A arm -O linux -T ramdisk -n "Recovery Ram Disk" -d ../../recovery.ramdisk.cpio.gz ../../initrd_recovery.u-boot
cd ../..
echo ""
echo "*******************************************"
echo "Done. Ramdisk file: initrd_recovery.u-boot"
echo ""
fi