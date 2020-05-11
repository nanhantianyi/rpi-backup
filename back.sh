#!/bin/bash

if [ `whoami` != "root" ];then
    echo "This script must be run as root!"
    exit 1
fi

# install software
apt update
apt install -y dosfstools parted kpartx rsync

echo ""
echo "software is ready"

file="rpi-`date +%Y%m%d%H%M%S`.img"

if [ "x$1" != "x" ];then
    file="$1"
fi

# boot mount point
boot_mnt=`findmnt -n /dev/mmcblk0p1 | awk '{print $1}'`

root_info=`df -PT / | tail -n 1`

root_type=`echo $root_info | awk '{print $2}'`

dr=`echo $root_info | awk '{print $4}'`
db=`df -P | grep /dev/mmcblk0p1 | awk '{print $2}'`
ds=`echo $dr $db |awk '{print int(($1+$2)*1.2)}'`

echo "create $file ..."

dd if=/dev/zero of=$file bs=1K count=0 seek=$ds
#truncate -s ${ds}k $file

start=`fdisk -l /dev/mmcblk0| awk 'NR==9 {print $2}'`
end=`fdisk -l /dev/mmcblk0| awk 'NR==9 {print $3}'`

if [ "$start" == "*" ];then
    start=`fdisk -l /dev/mmcblk0| awk 'NR==9 {print $3}'`
    end=`fdisk -l /dev/mmcblk0| awk 'NR==9 {print $4}'`
fi

start=`echo $start's'`
end=`echo $end's'`

end2=`fdisk -l /dev/mmcblk0| awk 'NR==10 {print $2}'`
end2=`echo $end2's'`

echo "start=$start"
echo "end=$end"
echo "end2=$end2"

parted $file --script -- mklabel msdos
parted $file --script -- mkpart primary fat32 $start $end
parted $file --script -- mkpart primary ext4 $end2 -1

loopdevice=`losetup -f --show $file`
device=`kpartx -va $loopdevice | sed -E 's/.*(loop[0-9])p.*/\1/g' | head -1`
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

boot_label=`dosfslabel /dev/mmcblk0p1 | tail -n 1`
root_label=`e2label /dev/mmcblk0p2 | tail -n 1`

mkfs.vfat -F 32 -n "$boot_label" $partBoot
echo "$partBoot format success"

mkfs.ext4 $partRoot
e2label $partRoot $root_label
echo "$partRoot format success"

mount -t vfat $partBoot /mnt
cp -rfp ${boot_mnt}/* /mnt/

sed -i "s/$opartuuidr/$npartuuidr/g" /mnt/cmdline.txt

sync

umount /mnt

mount -t ext4 $partRoot /mnt

if [ -f /etc/dphys-swapfile ]; then
    SWAPFILE=`cat /etc/dphys-swapfile | grep ^CONF_SWAPFILE | cut -f 2 -d=`
    if [ "$SWAPFILE" = "" ]; then
        SWAPFILE=/var/swap
    fi
    EXCLUDE_SWAPFILE="--exclude $SWAPFILE"
fi

cd /mnt

rsync --force -rltWDEgop --delete --stats --progress \
    $EXCLUDE_SWAPFILE \
    --exclude ".gvfs" \
    --exclude "$boot_mnt" \
    --exclude "/dev" \
    --exclude "/media" \
    --exclude "/mnt" \
    --exclude "/proc" \
    --exclude "/run" \
    --exclude "/snap" \
    --exclude "/sys" \
    --exclude "/tmp" \
    --exclude "lost\+found" \
    --exclude "$file" \
    / ./

if [ ! -d $boot_mnt ]; then
    mkdir $boot_mnt
fi

if [ -d /snap ]; then
    mkdir /mnt/snap
fi

for i in boot dev media mnt proc run sys boot; do
    if [ ! -d /mnt/$i ]; then
        mkdir /mnt/$i
    fi
done

if [ ! -d /mnt/tmp ]; then
    mkdir /mnt/tmp
    chmod a+w /mnt/tmp
fi

cd

sed -i "s/$opartuuidb/$npartuuidb/g" /mnt/etc/fstab
sed -i "s/$opartuuidr/$npartuuidr/g" /mnt/etc/fstab

sync

umount /mnt

kpartx -d $loopdevice
losetup -d $loopdevice


