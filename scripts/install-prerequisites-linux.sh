#!/usr/bin/env bash

#
# Linux Prerequisites Installation Script
# Installs required tools for Wander development environment
#

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo "========================================="
echo "Wander Prerequisites Installer (Linux)"
echo "========================================="
echo ""

# Detect Linux distribution
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$ID
else
    echo -e "${RED}Cannot detect Linux distribution${NC}"
    exit 1
fi

echo "Detected OS: $OS"
echo ""

# Check and install kubectl
echo "Checking kubectl..."
if command -v kubectl &> /dev/null; then
    echo -e "${GREEN}✓ kubectl already installed${NC}"
    kubectl version --client 2>/dev/null | head -n 1 || echo "  (version check skipped)"
else
    echo -e "${YELLOW}Installing kubectl...${NC}"
    
    # Check if we have sudo access
    if ! sudo -n true 2>/dev/null; then
        echo "Installing kubectl requires administrator privileges."
        echo "You may be prompted for your password."
        echo ""
    fi
    
    if curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" 2>/dev/null; then
        if sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl 2>/dev/null; then
            rm kubectl
            echo -e "${GREEN}✓ kubectl installed${NC}"
        else
            echo -e "${RED}✗ Failed to install kubectl (permission denied)${NC}"
            echo "Please install manually or run with sudo privileges"
            rm -f kubectl
        fi
    else
        echo -e "${RED}✗ Failed to download kubectl${NC}"
        echo "Please check your internet connection"
    fi
fi
echo ""

# Check and install minikube
echo "Checking minikube..."
if command -v minikube &> /dev/null; then
    echo -e "${GREEN}✓ minikube already installed${NC}"
    minikube version --short
else
    echo -e "${YELLOW}Installing minikube...${NC}"
    
    if curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64 2>/dev/null; then
        if sudo install minikube-linux-amd64 /usr/local/bin/minikube 2>/dev/null; then
            rm minikube-linux-amd64
            echo -e "${GREEN}✓ minikube installed${NC}"
        else
            echo -e "${RED}✗ Failed to install minikube (permission denied)${NC}"
            echo "Please install manually or run with sudo privileges"
            rm -f minikube-linux-amd64
        fi
    else
        echo -e "${RED}✗ Failed to download minikube${NC}"
        echo "Please check your internet connection"
    fi
fi
echo ""

# Check Docker
echo "Checking Docker..."
if command -v docker &> /dev/null; then
    echo -e "${GREEN}✓ Docker already installed${NC}"
    docker --version
else
    echo -e "${YELLOW}Installing Docker...${NC}"
    
    if [ "$OS" = "ubuntu" ] || [ "$OS" = "debian" ]; then
        if sudo -n true 2>/dev/null || sudo true 2>/dev/null; then
            sudo apt-get update && \
            sudo apt-get install -y docker.io && \
            sudo systemctl start docker && \
            sudo systemctl enable docker && \
            sudo usermod -aG docker $USER
            echo -e "${GREEN}✓ Docker installed${NC}"
            echo -e "${YELLOW}Note: You may need to log out and back in for Docker group changes to take effect${NC}"
        else
            echo -e "${RED}✗ Cannot install Docker (permission denied)${NC}"
            echo "Please install manually: https://docs.docker.com/engine/install/"
        fi
    else
        echo -e "${YELLOW}Please install Docker manually for your distribution${NC}"
        echo "Visit: https://docs.docker.com/engine/install/"
    fi
fi
echo ""

# Check envsubst
echo "Checking envsubst..."
if command -v envsubst &> /dev/null; then
    echo -e "${GREEN}✓ envsubst already installed${NC}"
else
    echo -e "${YELLOW}Installing gettext (envsubst)...${NC}"
    if [ "$OS" = "ubuntu" ] || [ "$OS" = "debian" ]; then
        sudo apt-get install -y gettext
    elif [ "$OS" = "fedora" ] || [ "$OS" = "rhel" ] || [ "$OS" = "centos" ]; then
        sudo yum install -y gettext
    fi
    echo -e "${GREEN}✓ envsubst installed${NC}"
fi
echo ""

# Final verification
echo "========================================="
echo "Final Verification"
echo "========================================="
echo ""

ALL_GOOD=true

if command -v docker &> /dev/null; then
    echo -e "${GREEN}✓ Docker:${NC} $(docker --version)"
else
    echo -e "${RED}✗ Docker: Not found${NC}"
    ALL_GOOD=false
fi

if command -v kubectl &> /dev/null; then
    echo -e "${GREEN}✓ kubectl:${NC} $(kubectl version --client --short 2>/dev/null || echo 'installed')"
else
    echo -e "${RED}✗ kubectl: Not found${NC}"
    ALL_GOOD=false
fi

if command -v minikube &> /dev/null; then
    echo -e "${GREEN}✓ minikube:${NC} $(minikube version --short 2>/dev/null || echo 'installed')"
else
    echo -e "${RED}✗ minikube: Not found${NC}"
    ALL_GOOD=false
fi

if command -v envsubst &> /dev/null; then
    echo -e "${GREEN}✓ envsubst:${NC} installed"
else
    echo -e "${RED}✗ envsubst: Not found${NC}"
    ALL_GOOD=false
fi

echo ""

if [ "$ALL_GOOD" = true ]; then
    echo -e "${GREEN}=========================================${NC}"
    echo -e "${GREEN}✓ All prerequisites installed!${NC}"
    echo -e "${GREEN}=========================================${NC}"
    echo ""
    echo "Next steps:"
    echo "  1. If Docker was just installed, log out and back in"
    echo "  2. Run: make validate"
    echo "  3. Run: make dev"
    echo ""
    exit 0
else
    echo -e "${RED}=========================================${NC}"
    echo -e "${RED}✗ Some prerequisites are missing${NC}"
    echo -e "${RED}=========================================${NC}"
    echo ""
    echo "Please install missing tools and try again."
    exit 1
fi
