#!/usr/bin/env bash

#
# Cross-Platform Prerequisites Installation Script
# Detects OS and calls appropriate installer
#

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

echo "========================================="
echo "Wander Prerequisites Installer"
echo "========================================="
echo ""

# Detect operating system
OS_TYPE=""
if [[ "$OSTYPE" == "darwin"* ]]; then
    OS_TYPE="macos"
    echo -e "${BLUE}Detected: macOS${NC}"
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    OS_TYPE="linux"
    echo -e "${BLUE}Detected: Linux${NC}"
elif [[ "$OSTYPE" == "msys" || "$OSTYPE" == "cygwin" ]]; then
    OS_TYPE="windows"
    echo -e "${BLUE}Detected: Windows (Git Bash/Cygwin)${NC}"
else
    echo -e "${RED}Unknown operating system: $OSTYPE${NC}"
    OS_TYPE="unknown"
fi

echo ""

# Function to check if we can use sudo
can_use_sudo() {
    if command -v sudo &> /dev/null; then
        # Check if we can run sudo without password or if password is cached
        if sudo -n true 2>/dev/null; then
            return 0
        else
            echo -e "${YELLOW}Note: Some installations require administrator privileges${NC}"
            echo "You may be prompted for your password."
            echo ""
            return 0
        fi
    else
        echo -e "${YELLOW}Warning: sudo not available${NC}"
        echo "You may need to run some commands manually with administrator privileges."
        echo ""
        return 1
    fi
}

# Route to appropriate installer
case $OS_TYPE in
    macos)
        if [ -f "scripts/install-prerequisites-macos.sh" ]; then
            echo "Running macOS installer..."
            echo ""
            can_use_sudo || true
            ./scripts/install-prerequisites-macos.sh
        else
            echo -e "${RED}Error: macOS installer script not found${NC}"
            exit 1
        fi
        ;;
    
    linux)
        if [ -f "scripts/install-prerequisites-linux.sh" ]; then
            echo "Running Linux installer..."
            echo ""
            can_use_sudo
            ./scripts/install-prerequisites-linux.sh
        else
            echo -e "${RED}Error: Linux installer script not found${NC}"
            exit 1
        fi
        ;;
    
    windows)
        echo -e "${YELLOW}Windows Installation${NC}"
        echo ""
        echo "For Windows, please use WSL2 (Windows Subsystem for Linux):"
        echo ""
        echo "1. Install WSL2:"
        echo "   wsl --install"
        echo ""
        echo "2. Install Docker Desktop for Windows with WSL2 integration:"
        echo "   https://www.docker.com/products/docker-desktop"
        echo ""
        echo "3. In WSL2, install kubectl and minikube:"
        echo "   curl -LO \"https://dl.k8s.io/release/\$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl\""
        echo "   sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl"
        echo ""
        echo "   curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64"
        echo "   sudo install minikube-linux-amd64 /usr/local/bin/minikube"
        echo ""
        echo "Alternatively, use Chocolatey (run as Administrator):"
        echo "   choco install kubernetes-cli minikube docker-desktop"
        echo ""
        exit 0
        ;;
    
    *)
        echo -e "${RED}Unsupported operating system${NC}"
        echo ""
        echo "Please install prerequisites manually:"
        echo ""
        echo "Required tools:"
        echo "  - Docker Desktop: https://www.docker.com/products/docker-desktop"
        echo "  - kubectl: https://kubernetes.io/docs/tasks/tools/"
        echo "  - minikube: https://minikube.sigs.k8s.io/docs/start/"
        echo "  - Node.js 20: https://nodejs.org/"
        echo ""
        exit 1
        ;;
esac

