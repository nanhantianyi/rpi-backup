# rpi-backup

树莓派系统备份脚本 

## 一、测试系统 

   1、2020-02-13-raspbian-buster-lite (成功)
   
   2、ubuntu-20.04-preinstalled-server-arm64 (成功)
   
   3、ubuntu-18.04-desktop-arm64 (成功)
   
   4、2019-12-30-OPENFANS-Debian-Buster-Aarch64-ext4-v2019-2.0-U2-Release-plus++ (成功)
   
## 二、back.sh（备份脚本，需要root权限） 

   用法：sudo bash back.sh xxx.img  (xxx.img为备份文件名，自行修改)

   **1. 备份镜像大小计算：(boot分区全部 + root分区已使用) * 1.2**
   
   **2. 如果sd卡剩余空间充足，可以备份到卡内，如果剩余空间有限，请备份到外部设备**
   
   **3. 如果需要备份到外部设备，设备务必挂载到/media,不要挂载到/mnt,因为创建的镜像会挂载到/mnt进行操作**
   
## 三、resize.sh（扩容脚本，需要root权限） 

   用法：恢复系统后执行 sudo bash resize.sh 扩容root分区，也可以用树莓派raspi-config进行扩容
   
## 四、参考资料  
   1. https://blog.csdn.net/lzjsqn/article/details/72058293  
   2. 4.14.114-OPENFANS+20190602-v8 64位debain系统 /usr/sbin/resize.root  脚本 
