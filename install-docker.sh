#!/bin/bash
set -e  # Stop script on first error

echo "=== Docker Installation Script ==="

# Detect distribution
if [ -f /etc/os-release ]; then
    . /etc/os-release
    DISTRO=$ID
else
    echo "Cannot detect Linux distribution."
    exit 1
fi

echo "Detected distribution: $DISTRO"

# Only allow Debian-based (Debian, Ubuntu, Kali, etc.)
if [[ "$DISTRO" != "debian" && "$DISTRO" != "ubuntu" && "$DISTRO" != "kali" ]]; then
    echo "Unsupported distribution: $DISTRO"
    exit 1
fi

echo "Removing old Docker versions (if present)..."
sudo apt-get remove -y docker docker-engine docker.io containerd runc || true

echo "Updating package index..."
sudo apt-get update -y

echo "Installing prerequisites..."
sudo apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg-agent \
    software-properties-common

echo "Adding Docker's official GPG key..."
curl -fsSL https://download.docker.com/linux/debian/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

echo "Setting up Docker repository..."
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] \
  https://download.docker.com/linux/debian \
  $(lsb_release -cs) stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

echo "Updating package index again..."
sudo apt-get update -y

echo "Installing Docker..."
sudo apt-get install -y docker-ce docker-ce-cli containerd.io

echo "Enabling and starting Docker service..."
sudo systemctl enable docker
sudo systemctl start docker

echo "Docker installed successfully!"
docker --version
#!/usr/bin/env bash
set -euo pipefail

echo "=== Docker Installation Script ==="

# Detect distribution
if [ -f /etc/os-release ]; then
    . /etc/os-release
    DISTRO=$ID
else
    echo "❌ Could not detect distribution."
    exit 1
fi

echo "Detected distribution: $DISTRO"

# Ensure script is run as root
if [ "$EUID" -ne 0 ]; thens
    echo "❌ Please run as root (sudo ./install-docker.sh)"
    exit 1
fi

# Remove old Docker versions
echo "Removing old Docker versions (if present)..."
apt-get remove -y docker docker-engine docker.io containerd runc || true

# For Kali/Debian-based distros
if [[ "$DISTRO" == "kali" || "$DISTRO" == "debian" || "$DISTRO" == "ubuntu" ]]; then
    echo "Updating package index..."
    apt-get update -y

    echo "Installing prerequisites..."
    apt-get install -y \
        apt-transport-https \
        ca-certificates \
        curl \
        gnupg \
        lsb-release

    echo "Adding Docker's official GPG key..."
    install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    chmod a+r /etc/apt/keyrings/docker.gpg

    echo "Setting up Docker repository..."
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian \
      $(lsb_release -cs) stable" > /etc/apt/sources.list.d/docker.list

    echo "Updating package index (with Docker repo)..."
    apt-get update -y

    echo "Installing Docker..."
    apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

    echo "Enabling and starting Docker service..."
    systemctl enable docker
    systemctl start docker

    echo "✅ Docker installation completed successfully."
    docker --version
    docker compose version
else
    echo "❌ Unsupported distribution: $DISTRO"
    exit 1
fi
