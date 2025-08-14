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
if [ "$EUID" -ne 0 ]; then
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
