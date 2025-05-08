#!/usr/bin/env bash
set -euo pipefail

# Prerequisites
sudo apt update
sudo apt install -y uidmap dbus-user-session curl bash-completion

# Install Docker rootless
curl -fsSL https://get.docker.com/rootless | sh

# Environment variables
if ! grep -q DOCKER_HOST ~/.bashrc; then
  echo 'export PATH=$HOME/bin:$PATH' >> ~/.bashrc
  echo 'export DOCKER_HOST=unix://$XDG_RUNTIME_DIR/docker.sock' >> ~/.bashrc
fi

export PATH=$HOME/bin:$PATH
export DOCKER_HOST=unix://$XDG_RUNTIME_DIR/docker.sock

# Enable Docker service
systemctl --user enable docker
systemctl --user start docker
loginctl enable-linger $USER

# AppArmor fix for Ubuntu 24.04
filename=$(echo $HOME/bin/rootlesskit | sed -e s@^/@@ -e s@/@.@g)
cat <<EOF > ~/${filename}
abi <abi/4.0>,
include <tunables/global>

"$HOME/bin/rootlesskit" flags=(unconfined) {
  userns,
  include if exists <local/${filename}>
}
EOF

sudo mv ~/${filename} /etc/apparmor.d/${filename}
sudo apparmor_parser -r /etc/apparmor.d/${filename}
sudo systemctl restart apparmor
systemctl --user restart docker

# Install Docker Compose plugin
mkdir -p ~/.docker/cli-plugins
curl -SL https://github.com/docker/compose/releases/download/v2.28.1/docker-compose-linux-x86_64 -o ~/.docker/cli-plugins/docker-compose
chmod +x ~/.docker/cli-plugins/docker-compose

# Enable Bash completions
sudo mkdir -p /etc/bash_completion.d
docker completion bash | sudo tee /etc/bash_completion.d/docker > /dev/null
echo 'complete -F __start_docker docker-compose' >> ~/.bashrc

# Ensure runtime dir is exported
if ! grep -q XDG_RUNTIME_DIR ~/.bashrc; then
  echo 'export XDG_RUNTIME_DIR=/run/user/$(id -u)' >> ~/.bashrc
fi

source ~/.bashrc

echo "✅ Rootless Docker with Compose is installed. Run 'docker info' and 'docker compose version' to verify."
