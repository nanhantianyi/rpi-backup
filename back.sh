#!/bin/bash
sudo apt install -y dosfstools parted kpartx rsync

echo ""
echo "software is ready"

file="rpi.img"

if [ "x$1" != "x" ];then
    file="$1"
fi

dr=`df -P | grep /dev/root | awk '{print $3}'`
db=`df -P | grep /dev/mmcblk0p1 | awk '{print $2}'`
ds=`echo $dr $db |awk '{print int(($1+$2)*1.2)}'`

echo "create $file ..."

sudo dd if=/dev/zero of=$file bs=1K count=0 seek=$ds
#sudo truncate -s ${ds}k $file

start=`sudo fdisk -l /dev/mmcblk0| awk 'NR==9 {print $2}'`
end=`sudo fdisk -l /dev/mmcblk0| awk 'NR==9 {print $3}'`

if [ "$start" == "*" ];then
    start=`sudo fdisk -l /dev/mmcblk0| awk 'NR==9 {print $3}'`
    end=`sudo fdisk -l /dev/mmcblk0| awk 'NR==9 {print $4}'`
fi

start=`echo $start's'`
end=`echo $end's'`

end2=`sudo fdisk -l /dev/mmcblk0| awk 'NR==10 {print $2}'`
end2=`echo $end2's'`

echo "start=$start"
echo "end=$end"
echo "end2=$end2"

sudo parted $file --script -- mklabel msdos
sudo parted $file --script -- mkpart primary fat32 $start $end
sudo parted $file --script -- mkpart primary ext4 $end2 -1

loopdevice=`sudo losetup -f --show $file`
device=`sudo kpartx -va $loopdevice | sed -E 's/.*(loop[0-9])p.*/\1/g' | head -1`
device="/dev/mapper/${device}"

echo "device=$device"

partBoot="${device}p1"
partRoot="${device}p2"

echo "partBoot=$partBoot"
echo "partRoot=$partRoot"

sleep 5s

opartuuidb=`blkid -o export /dev/mmcblk0p1 | grep PARTUUID`
opartuuidr=`blkid -o export /dev/mmcblk0p2 | grep PARTUUID`

npartuuidb=`blkid -o export ${partBoot} | grep PARTUUID`
npartuuidr=`blkid -o export ${partRoot} | grep PARTUUID`


sudo mkfs.vfat -F 32 -n "boot" $partBoot
echo "$partBoot format success"

sudo mkfs.ext4 $partRoot
echo "$partRoot format success"

sudo mount -t vfat $partBoot /mnt
sudo cp -rfp /boot/* /mnt/

sudo sed -i "s/$opartuuidr/$npartuuidr/g" /mnt/cmdline.txt

sync

sudo umount /mnt

sudo mount -t ext4 $partRoot /mnt

if [ -f /etc/dphys-swapfile ]; then
    SWAPFILE=`cat /etc/dphys-swapfile | grep ^CONF_SWAPFILE | cut -f 2 -d=`
    if [ "$SWAPFILE" = "" ]; then
        SWAPFILE=/var/swap
    fi
    EXCLUDE_SWAPFILE="--exclude $SWAPFILE"
fi

cd /mnt

sudo rsync --force -rltWDEgop --delete --stats --progress \
    $EXCLUDE_SWAPFILE \
    --exclude ".gvfs" \
    --exclude "/boot" \
    --exclude "/dev" \
    --exclude "/media" \
    --exclude "/mnt" \
    --exclude "/proc" \
    --exclude "/run" \
    --exclude "/sys" \
    --exclude "/tmp" \
    --exclude "lost\+found" \
    --exclude "$file" \
    / ./

for i in boot dev media mnt proc run sys boot; do
    if [ ! -d /mnt/$i ]; then
        sudo mkdir /mnt/$i
    fi
done

if [ ! -d /mnt/tmp ]; then
    sudo mkdir /mnt/tmp
    sudo chmod a+w /mnt/tmp
fi

cd

sudo sed -i "s/$opartuuidb/$npartuuidb/g" /mnt/etc/fstab
sudo sed -i "s/$opartuuidr/$npartuuidr/g" /mnt/etc/fstab

sync

sudo umount /mnt

sudo kpartx -d $loopdevice
sudo losetup -d $loopdevice


