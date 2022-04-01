# How to build custom docker images on a debian / ubuntu system
* Install debootstrap
```
sudo apt install debootstrap -y
```

* Create a working dir
```
cd ~/
mkdir mysql_node_2004
```

* Download ubuntu focal minimum base image files, and include mysql package
```
sudo debootstrap --arch=amd64 --variant=minbase --include=mysql-server focal ./mysql_node_2004 http://gb.archive.ubuntu.com/ubuntu
```

* chroot into image folder to make changes before deploying as docker image
```
sudo chroot mysql_node_2004 /bin/bash
```

* Install node into the image and exit out of chroot
```
apt install wget -y
wget -qO- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.1/install.sh | bash
source ~/.bashrc
nvm install node
exit
```

* Build docker image
```
sudo tar -C mysql_node_2004 -c . | docker import - eodeluga/node:latest-2004-mysql
```
