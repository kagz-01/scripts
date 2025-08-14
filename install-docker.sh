#!/bin/bash

echo "=== Docker Installation Script ==="

# Detect distribution
if [ -f /etc/os-release ]; then
    . /etc/os-release
    DISTRO=$ID
else
    echo "Cannot detect Linux distribution."
    exit 1
fi

# Treat Kali as Debian
if [[ "$DISTRO" == "kali" ]]; then
    echo "Detected Kali Linux - using Debian instructions."
    DISTRO="debian"
fi

echo "Detected distribution: $DISTRO"

# Remove old versions
echo "Removing old Docker versions (if present)..."
sudo apt remove -y docker docker-engine docker.io containerd runc

# Install dependencies
echo "Installing dependencies..."
sudo apt update -y && sudo apt install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    lsb-release

# Add Docker's official GPG key
echo "Adding Docker GPG key..."
curl -fsSL https://download.docker.com/linux/$DISTRO/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

# Set up the stable repository
echo "Setting up Docker repository..."
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/$DISTRO \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Install Docker Engine
echo "Installing Docker..."
sudo apt update -y && sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Enable & start Docker
echo "Enabling and starting Docker..."
sudo systemctl enable docker
sudo systemctl start docker

# Test Docker installation
echo "Testing Docker..."
sudo docker run hello-world

echo "=== Docker installation completed successfully! ==="
