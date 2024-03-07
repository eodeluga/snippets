#!/bin/bash

# Install NVM
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.3/install.sh | bash

# Install Docker (rootless)
sudo apt-get install uidmap -y
curl -fsSL https://get.docker.com/rootless | sh
sudo curl https://raw.githubusercontent.com/docker/docker-ce/master/components/cli/contrib/completion/bash/docker -o /etc/bash_completion.d/docker.sh
systemctl --user enable docker.service
systemctl --user start docker.service

# Install Docker (uncomment to install in root mode)
# sudo apt-get update -y
# sudo apt-get install ca-certificates curl gnupg -y
# sudo install -m 0755 -d /etc/apt/keyrings
# curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
# sudo chmod a+r /etc/apt/keyrings/docker.gpg
# echo \
#  "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
#  "$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" | \
#  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
#  sudo apt-get update -y
#  sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y
#  sudo usermod -aG docker $USER
#  sudo systemctl enable docker
#  sudo systemctl start docker

# Install Brave
sudo apt install curl -y
sudo curl -fsSLo /usr/share/keyrings/brave-browser-archive-keyring.gpg https://brave-browser-apt-release.s3.brave.com/brave-browser-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/brave-browser-archive-keyring.gpg] https://brave-browser-apt-release.s3.brave.com/ stable main"|sudo tee /etc/apt/sources.list.d/brave-browser-release.list
sudo apt update -y
sudo apt upgrade -y
sudo apt install brave-browser -y

# Add paths to .bashrc
echo '' | tee -a ~/.bashrc
echo '# Add NVM to path' | tee -a ~/.bashrc
echo 'export NVM_DIR="$HOME/.nvm"' | tee -a ~/.bashrc
echo '[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm' | tee -a ~/.bashrc
echo '[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion' | tee -a ~/.bashrc
echo '' | tee -a ~/.bashrc
echo '# Add docker-compose to path' | tee -a ~/.bashrc
echo 'export DOCKER_CONFIG=${DOCKER_CONFIG:-$HOME/.docker}' | tee -a ~/.bashrc
echo 'export PATH="$DOCKER_CONFIG/cli-plugins:$PATH"' | tee -a ~/.bashrc

# Install Docker Compose
# bash -c "source ~/.bashrc && source ~/.profile && mkdir -p $DOCKER_CONFIG/cli-plugins && curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o $DOCKER_CONFIG/cli-plugins/docker-compose && chmod +x $DOCKER_CONFIG/cli-plugins/docker-compose"
# mkdir -p $DOCKER_CONFIG/cli-plugins
# curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o $DOCKER_CONFIG/cli-plugins/docker-compose
# chmod +x $DOCKER_CONFIG/cli-plugins/docker-compose
