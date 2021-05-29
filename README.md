# rpi-backup

树莓派系统备份脚本

Make the entire snapshot of a system in SD card

## 一、近期系统测试 (Recently Tests)
   
   - [x] ubuntu-20.04-preinstalled-server-arm64
   
   - [ ] ubuntu-18.04-desktop-arm64
      
## 二、back.sh（Backup, need root） 

   `USAGE`：`sudo bash back.sh xxx.img(option)`  
   
   - `xxx.img`:  custom name for backup, if empty, the default name is `rpi-YYYYmmddHHMMSS.img`
   
   **1. 备份镜像大小计算：(boot分区全部 + root分区已使用) * 1.2**
   
   **2. 如果sd卡剩余空间充足，可以备份到卡内，如果剩余空间有限，请备份到外部设备**
   
   **3. 如果需要备份到外部设备，设备务必挂载到/media,不要挂载到/mnt,因为创建的镜像会挂载到/mnt进行操作**
   
## 三、resize.sh (Resize, need root) 

   ~~用法：恢复系统后执行 sudo bash resize.sh 扩容root分区，也可以用树莓派raspi-config进行扩容~~
   
## 四、参考资料  
   1. https://blog.csdn.net/lzjsqn/article/details/72058293  
   2. 4.14.114-OPENFANS+20190602-v8 64位debain系统 /usr/sbin/resize.root  脚本 
