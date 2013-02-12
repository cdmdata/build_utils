#!/bin/sh
DRIVE=$1
SOURCEDIR=$2


if [ $# -ne 2 ]; then
    echo "Error: wrong number of arguments in cmd: $0 $* "
    return
fi

echo "About to wipe $DRIVE and copy from $SOURCEDIR...";
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
sudo mkfs.ext4 -L DATA ${DRIVE}5
sudo mkfs.ext4 -L RECOVERY ${DRIVE}6
sudo mkfs.ext4 -L CACHE ${DRIVE}7
sudo mkfs.vfat -F 32 -n MEDIA ${DRIVE}4

echo "Reimaging partitions...";
echo "Restoring boot..."
IMAGE_FILE=${SOURCEDIR}/fatboot.img
sudo dd if=$IMAGE_FILE of=${DRIVE}1 bs=4096

echo "Restoring system...";
IMAGE_FILE=${SOURCEDIR}/system.img
sudo dd if=$IMAGE_FILE of=${DRIVE}2 bs=4096

echo "Restoring userdata...";
IMAGE_FILE=${SOURCEDIR}/userdata.img
sudo dd if=$IMAGE_FILE of=${DRIVE}5 bs=4096

sync
fi


