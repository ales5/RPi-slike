# fstab configuration:
## Find the hard disk UUID:
sudo blkid
## Create mount point
sudo mkdir -p /mnt/server_slike
## Edit fstab configuration
UUID=XXXX-XXXX  /mnt/server_slike  ntfs  defaults,nofail,uid=1000,gid=1000,umask=000  0  2
- nofail so that if hrad drive is not detected the boot does not hang
- uid, gid makes the uid=1000 and guid=1000 the owner of the files aka pi user (this user is also necessary for docker container that wants to access the files)
- umask=0000 read/write/execute permissions to everyone on network
- 0: tells the dump utility whether to back up this filesystem. Not commonly used.
- 2: fsck order — controls the order filesystems are checked at boot (0: never check this filesystem at boot; 1: check first (usually / root filesystem); 2: check after the root filesystem)


