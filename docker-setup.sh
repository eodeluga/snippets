#!/bin/bash
# Install docker engine and docker compose

# Remove existing docker
sudo snap remove docker

# Update the apt package index and install packages to allow apt to use a repository over HTTPS
sudo apt-get update -y
sudo apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg-agent \
    software-properties-common

# Add Docker’s official GPG key:
curl -fsSL https://download.docker.com/linux/debian/gpg | sudo apt-key add -

# Add docker repository. Have to use eoan release on Ubuntu 20 which currently lacks a release file
sudo add-apt-repository -y \
   "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
   eoan stable"
   
# Install Docker engine
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io

# Install Docker compose
sudo curl -L \
  "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" \
  -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Add logged in user to docker group to allow running of docker commands without elevation
sudo usermod -a -G docker $(echo $USERNAME)

# Need to add cgroup support for some containers
#
# Create a systemd service that mounts cgroup at boot
sudo su -c "echo -e '[Unit]
Description=Docker mount cgroup
After=network.target\n
[Service]
ExecStart=/usr/local/bin/mount-cgroup.sh\n
[Install]
WantedBy=multi-user.target'" >> /etc/systemd/system/mount-cgroup.service

# Create the script the service executes
sudo su -c "echo -e '#!/bin/bash\n
# Mounts cgroup for Docker
sudo mkdir /sys/fs/cgroup/systemd
sudo mount -t cgroup -o none,name=systemd cgroup /sys/fs/cgroup/systemd'" >> /usr/local/bin/mount-cgroup.sh

# Set permissions for newly created files
sudo chmod 744 /usr/local/bin/mount-cgroup.sh
sudo chmod 664 /etc/systemd/system/mount-cgroup.service

# Enable the service
sudo systemctl daemon-reload
sudo systemctl enable mount-cgroup.service
