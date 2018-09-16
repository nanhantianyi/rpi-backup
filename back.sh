#!/bin/bash
sudo apt-get install -y dosfstools parted kpartx rsync

df=`df -P | grep /dev/root | awk '{print $3}'`
dr=`df -P | grep /dev/mmcblk0p1 | awk '{print $2}'`
df=`echo $df $dr |awk '{print int(($1+$2)*1.2)}'`
#df=`echo $df $dr |awk '{print int(($2)*2)}'`
sudo dd if=/dev/zero of=raspberrypi.img bs=1K count=$df

sudo parted raspberrypi.img --script -- mklabel msdos

start=`sudo fdisk -l /dev/mmcblk0| awk 'NR==9 {print $2}'`
start=`echo $start's'`
end=`sudo fdisk -l /dev/mmcblk0| awk 'NR==9 {print $3}'`
end=`echo $end's'`
end2=`sudo fdisk -l /dev/mmcblk0| awk 'NR==10 {print $2}'`
end2=`echo $end2's'`

echo "start=$start"
echo "end=$end"
echo "end2=$end2"

sudo parted raspberrypi.img --script -- mkpart primary fat32 $start $end
sudo parted raspberrypi.img --script -- mkpart primary ext4 $end2 -1

loopdevice=`sudo losetup -f --show raspberrypi.img`
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

sudo mount -t vfat $partBoot /media
sudo cp -rfp /boot/* /media/

sudo sed -i "s/$opartuuidr/$npartuuidr/g" /media/cmdline.txt

sudo umount /media

sudo mount -t ext4 $partRoot /media

if [ -f /etc/dphys-swapfile ]; then
	SWAPFILE=`cat /etc/dphys-swapfile | grep ^CONF_SWAPFILE | cut -f 2 -d=`
	if [ "$SWAPFILE" = "" ]; then
		SWAPFILE=/var/swap
	fi
	EXCLUDE_SWAPFILE="--exclude $SWAPFILE"
fi

cd /media

sudo rsync --force -rltWDEgop --delete --stats --progress \
	$EXCLUDE_SWAPFILE \
	--exclude '.gvfs' \
	--exclude '/dev' \
	--exclude '/media' \
	--exclude '/mnt' \
	--exclude '/proc' \
	--exclude '/run' \
	--exclude '/sys' \
	--exclude '/tmp' \
	--exclude 'lost\+found' \
	--exclude 'raspberrypi.img' \
	/ ./

for i in dev media mnt proc run sys boot; do
	if [ ! -d /media/$i ]; then
		sudo mkdir /media/$i
	fi
done

if [ ! -d /media/tmp ]; then
	sudo mkdir /media/tmp
	sudo chmod a+w /media/tmp
fi

cd

sudo sed -i "s/$opartuuidb/$npartuuidb/g" /media/etc/fstab
sudo sed -i "s/$opartuuidr/$npartuuidr/g" /media/etc/fstab

sudo umount /media

sudo kpartx -d $loopdevice
sudo losetup -d $loopdevice


