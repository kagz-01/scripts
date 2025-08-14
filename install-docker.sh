#!/usr/bin/env bash

set -e  # Exit immediately on error
set -u  # Treat unset variables as errors
set -o pipefail # Catch errors in piped commands

# Colors for messages
GREEN="\033[1;32m"
RED="\033[1;31m"
YELLOW="\033[1;33m"
NC="\033[0m"

echo -e "${GREEN}=== Docker Installation Script ===${NC}"

# Check if running as root
if [[ $EUID -ne 0 ]]; then
  echo -e "${RED}Please run this script as root (sudo)${NC}"
  exit 1
fi

# Detect distro
if [ -f /etc/os-release ]; then
    . /etc/os-release
    DISTRO=$ID
else
    echo -e "${RED}Cannot detect OS distribution.${NC}"
    exit 1
fi

echo -e "${YELLOW}Detected distribution: $DISTRO${NC}"

# Remove old versions of Docker if any
echo -e "${YELLOW}Removing old Docker versions (if present)...${NC}"
apt_remove() {
    apt-get remove -y docker docker-engine docker.io containerd runc || true
}

dnf_remove() {
    dnf remove -y docker docker-client docker-client-latest docker-common docker-latest docker-latest-logrotate docker-logrotate docker-engine || true
}

case "$DISTRO" in
    ubuntu|debian)
        apt_remove
        echo -e "${YELLOW}Installing dependencies...${NC}"
        apt-get update -y
        apt-get install -y apt-transport-https ca-certificates curl gnupg lsb-release

        echo -e "${YELLOW}Adding Docker GPG key...${NC}"
        curl -fsSL https://download.docker.com/linux/${DISTRO}/gpg | gpg --dearmor -o /usr/share/keyrings/docker.gpg

        echo -e "${YELLOW}Adding Docker repository...${NC}"
        echo \
          "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker.gpg] https://download.docker.com/linux/${DISTRO} \
          $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

        echo -e "${YELLOW}Installing Docker...${NC}"
        apt-get update -y
        apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
        ;;
    fedora|centos|rhel)
        dnf_remove
        echo -e "${YELLOW}Setting up Docker repository...${NC}"
        dnf -y install dnf-plugins-core
        dnf config-manager --add-repo https://download.docker.com/linux/${DISTRO}/docker-ce.repo

        echo -e "${YELLOW}Installing Docker...${NC}"
        dnf install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
        ;;
    *)
        echo -e "${RED}Unsupported distribution: $DISTRO${NC}"
        exit 1
        ;;
esac

# Enable and start Docker
echo -e "${YELLOW}Enabling and starting Docker service...${NC}"
systemctl enable docker
systemctl start docker

# Verify installation
if docker --version &>/dev/null; then
    echo -e "${GREEN}Docker installed successfully: $(docker --version)${NC}"
else
    echo -e "${RED}Docker installation failed.${NC}"
    exit 1
fi

if docker compose version &>/dev/null; then
    echo -e "${GREEN}Docker Compose installed successfully: $(docker compose version)${NC}"
else
    echo -e "${RED}Docker Compose installation failed.${NC}"
    exit 1
fi

echo -e "${GREEN}=== Docker installation completed successfully! ===${NC}"
echo -e "${YELLOW}You can now run: sudo docker run hello-world${NC}"
