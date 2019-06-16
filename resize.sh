#!/bin/bash
FSTYPE=$(cat /proc/cmdline |tr ' ' '\n' | awk -F= '/rootfstype/{print $2}')
BLKDEV_ROOTPART=$(findmnt / -o SOURCE -n)
ROOTPART_SEQ=$(echo $BLKDEV_ROOTPART | grep -o "[0-9]$")
BLKDEV_ROOTPART_NAME=$(echo $BLKDEV_ROOTPART | cut -d "/" -f 3)
BLKDEV=/dev/$(find /sys/block/*/ | grep $BLKDEV_ROOTPART_NAME$ | cut -d "/" -f 4)
RESIZE_TARGET=$BLKDEV_ROOTPART

if [ ! $RESIZER ]; then
    case $FSTYPE in
        f2fs)
            RESIZER=$(which resize.f2fs)
            ;;
        ext2|ext3|ext4)
            RESIZER=$(which resize2fs)
            ;;
        btrfs)
            RESIZER=$(which btrfs)
            RESIZER_ARGS="filesystem resize max"
            RESIZE_TARGET="/"
            mount -o remount,rw $RESIZE_TARGET
            ;;
        *)
            RESIZER=$(which resize.$FSTYPE)
            echo "FSTYPE is $FSTYPE, RESIZER could be $RESIZER"
            ;;
    esac
    if [ ! -e $RESIZER ]; then
        echo "Filesystem resizer for $FSTYPE not found!"
        exit 1
    fi
fi

echo "Resizing partiton..."
parted -s $BLKDEV -- resizepart $ROOTPART_SEQ 100%

echo "Informing kernel..."
# Make sure we have updated partition info
partx -u $BLKDEV
partx -u $BLKDEV_ROOTPART
partprobe $BLKDEV
partprobe $BLKDEV_ROOTPART

echo "Resizing filesystem..."
$RESIZER $RESIZER_ARGS $RESIZE_TARGET

systemctl daemon-reload 2>/dev/null
ldconfig 2>/dev/null

echo "Syncing to disk..."
sync && sync

echo ''
echo "Rebooting in 5 seconds..."
a=5
for i in $(seq 1 5); do
echo $a
sleep 1
a=$((a-1))
done

echo "Rebooting..."
init 6
