#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<EOF
Usage: $0 [--help|--uninstall]
  --help       show this message
  --uninstall remove rootless Docker and clean up installed rootless config
EOF
}

remove_rootless_env() {
  if [[ -f "$HOME/.bashrc" ]]; then
    sed -i \
      -e '/^# Docker Rootless environment$/d' \
      -e '/^export PATH=\$HOME\/bin:\$PATH$/d' \
      -e '/^export DOCKER_HOST=unix:\/\/\$XDG_RUNTIME_DIR\/docker.sock$/d' \
      -e '/^export XDG_RUNTIME_DIR=\/run\/user\/\$(id -u)$/d' \
      -e '/^complete -F __start_docker docker-compose$/d' \
      "$HOME/.bashrc"
  fi
}

remove_apparmor_profile() {
  filename=$(echo "$HOME/bin/rootlesskit" | sed -e 's@^/@@' -e 's@/@.@g')
  if [[ -f "/etc/apparmor.d/${filename}" ]]; then
    if command -v apparmor_parser >/dev/null 2>&1; then
      sudo apparmor_parser -R "/etc/apparmor.d/${filename}" || true
    fi
    sudo rm -f "/etc/apparmor.d/${filename}"
  fi
}

install_apparmor_profile() {
  # Ubuntu restricts unprivileged user namespaces with AppArmor.  RootlessKit
  # needs an explicit userns grant before either Docker's installer or the
  # user service attempts to start it.
  if ! source /etc/os-release || [[ "$ID" != "ubuntu" ]]; then
    echo "⚠️ Skipping AppArmor rootless Docker fix: not running Ubuntu."
    return
  fi

  ubuntu_major=${VERSION_ID%%.*}
  if [[ ! "$ubuntu_major" =~ ^[0-9]+$ ]] || (( ubuntu_major < 24 )); then
    echo "⚠️ Skipping AppArmor rootless Docker fix: Ubuntu $VERSION_ID is older than 24."
    return
  fi

  if grep -qEi 'microsoft|wsl' /proc/version 2>/dev/null || \
      grep -qEi 'microsoft|wsl' /proc/sys/kernel/osrelease 2>/dev/null; then
    echo "⚠️ Running under WSL; AppArmor support is unavailable in this kernel. Skipping Ubuntu 24+ AppArmor fix."
    return
  fi

  filename=$(echo "$HOME/bin/rootlesskit" | sed -e 's@^/@@' -e 's@/@.@g')
  profile_tmp=$(mktemp)
  trap 'rm -f "$profile_tmp"' EXIT
  cat > "$profile_tmp" <<EOF
abi <abi/4.0>,
include <tunables/global>

"$HOME/bin/rootlesskit" flags=(unconfined) {
  userns,

  # Site-specific additions and overrides. See local/README for details.
  include if exists <local/${filename}>
}
EOF

  sudo install -D -m 0644 "$profile_tmp" "/etc/apparmor.d/${filename}"
  sudo apparmor_parser -r "/etc/apparmor.d/${filename}"
  rm -f "$profile_tmp"
  trap - EXIT
}

uninstall_rootless_docker() {
  echo "Removing rootless Docker..."

  systemctl --user stop docker.service || true
  systemctl --user disable docker.service || true
  loginctl disable-linger "$USER" || true

  remove_rootless_env

  rm -f "$HOME/bin/docker" "$HOME/bin/dockerd" "$HOME/bin/docker-proxy" \
    "$HOME/bin/docker-compose" "$HOME/bin/rootlesskit" "$HOME/bin/slirp4netns"
  rm -f "$HOME/.docker/cli-plugins/docker-compose"
  rm -rf "$HOME/.config/systemd/user/docker.service" \
    "$HOME/.config/systemd/user/docker.socket" \
    "$HOME/.config/systemd/user/docker.service.d"
  rm -rf "$HOME/.config/docker" "$HOME/.local/share/docker" \
    "$HOME/.local/share/containerd"

  remove_apparmor_profile

  systemctl --user daemon-reload || true

  echo "✅ Rootless Docker uninstall complete."
}

if [[ "${1:-}" =~ ^(-h|--help)$ ]]; then
  usage
  exit 0
fi

if [[ "${1:-}" == "--uninstall" ]]; then
  uninstall_rootless_docker
  exit 0
fi

if [[ $# -gt 0 ]]; then
  usage
  exit 1
fi

# Prerequisites
sudo apt update
sudo apt install -y uidmap dbus-user-session curl bash-completion iptables apparmor apparmor-utils

# Docker's rootless prerequisite check requires the nftables kernel module.
# To deliberately bypass that check, invoke this script with SKIP_IPTABLES=1.
if [[ "${SKIP_IPTABLES:-0}" != "1" ]]; then
  if ! sudo modprobe nf_tables; then
    echo "Error: could not load the nf_tables kernel module." >&2
    echo "Install/enable nftables kernel support, or rerun with SKIP_IPTABLES=1 to bypass Docker's iptables check." >&2
    exit 1
  fi
else
  export SKIP_IPTABLES
  echo "⚠️ SKIP_IPTABLES=1: skipping the nf_tables prerequisite."
fi

# This must happen before get.docker.com/rootless, because that installer may
# immediately start RootlessKit and Docker.
install_apparmor_profile

# Install Docker rootless
curl -fsSL https://get.docker.com/rootless | sh

# Environment variables
if ! grep -q DOCKER_HOST ~/.bashrc; then
  echo '# Docker Rootless environment' >> ~/.bashrc
  echo 'export PATH=$HOME/bin:$PATH' >> ~/.bashrc
  echo 'export DOCKER_HOST=unix://$XDG_RUNTIME_DIR/docker.sock' >> ~/.bashrc
fi

export PATH="$HOME/bin:$PATH"
export XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
export DOCKER_HOST="unix://$XDG_RUNTIME_DIR/docker.sock"

# Enable Docker service
systemctl --user enable docker
systemctl --user start docker
loginctl enable-linger "$USER"

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
