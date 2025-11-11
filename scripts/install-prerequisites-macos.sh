#!/usr/bin/env bash

#
# macOS Prerequisites Installation Script
# Installs required tools for Wander development environment
#

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Function to check if Docker daemon is running
is_docker_running() {
    docker info &> /dev/null
}

# Function to wait for Docker to be ready
wait_for_docker() {
    echo "Waiting for Docker to start..."
    local max_attempts=60
    local attempt=0
    
    while [ $attempt -lt $max_attempts ]; do
        if is_docker_running; then
            echo -e "${GREEN}✓ Docker is running${NC}"
            return 0
        fi
        echo -n "."
        sleep 2
        attempt=$((attempt + 1))
    done
    
    echo ""
    echo -e "${RED}✗ Docker failed to start within 2 minutes${NC}"
    return 1
}

echo "========================================="
echo "Wander Prerequisites Installer (macOS)"
echo "========================================="
echo ""

# Check if Homebrew is installed
if ! command -v brew &> /dev/null; then
    echo -e "${YELLOW}⚠️  Homebrew not found${NC}"
    echo "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    
    # Add Homebrew to PATH for this session based on architecture
    ARCH=$(uname -m)
    if [[ "$ARCH" == "arm64" ]]; then
        if [ -f "/opt/homebrew/bin/brew" ]; then
            eval "$(/opt/homebrew/bin/brew shellenv)"
        fi
    else
        if [ -f "/usr/local/bin/brew" ]; then
            eval "$(/usr/local/bin/brew shellenv)"
        fi
    fi
    
    echo -e "${GREEN}✓ Homebrew installed${NC}"
else
    echo -e "${GREEN}✓ Homebrew is installed${NC}"
fi
echo ""

# Check and install kubectl
echo "Checking kubectl..."
if command -v kubectl &> /dev/null; then
    echo -e "${GREEN}✓ kubectl already installed${NC}"
    kubectl version --client 2>/dev/null || kubectl version --client --short 2>/dev/null || echo "installed"
else
    echo -e "${YELLOW}Installing kubectl...${NC}"
    brew install kubectl
    echo -e "${GREEN}✓ kubectl installed${NC}"
fi
echo ""

# Check and install minikube
echo "Checking minikube..."
ARCH=$(uname -m)
MINIKUBE_NEEDS_REINSTALL=false

if command -v minikube &> /dev/null; then
    # Check the actual binary architecture
    MINIKUBE_PATH=$(which minikube)
    if [ -f "$MINIKUBE_PATH" ]; then
        FILE_ARCH=$(file "$MINIKUBE_PATH" 2>/dev/null | grep -o "arm64\|x86_64\|amd64" | head -1 || echo "")
        
        # Also check for architecture warning in minikube output
        MINIKUBE_OUTPUT=$(minikube version --short 2>&1)
        HAS_ARCH_WARNING=false
        if echo "$MINIKUBE_OUTPUT" | grep -qi "amd64.*M1\|darwin/arm64"; then
            HAS_ARCH_WARNING=true
        fi
        
        if [[ "$ARCH" == "arm64" ]]; then
            # On Apple Silicon, check if we have the wrong architecture
            if [[ "$FILE_ARCH" == "x86_64" ]] || [[ "$FILE_ARCH" == "amd64" ]] || [ "$HAS_ARCH_WARNING" = true ]; then
                echo -e "${YELLOW}⚠️  Wrong architecture detected (amd64 on Apple Silicon)${NC}"
                MINIKUBE_NEEDS_REINSTALL=true
            elif [[ "$FILE_ARCH" == "arm64" ]]; then
                echo -e "${GREEN}✓ minikube already installed (ARM64)${NC}"
                minikube version --short 2>/dev/null || echo "installed"
            else
                # Can't determine from file, test if it works without warnings
                if [ "$HAS_ARCH_WARNING" = true ]; then
                    echo -e "${YELLOW}⚠️  minikube has architecture issues${NC}"
                    MINIKUBE_NEEDS_REINSTALL=true
                elif minikube version --short &> /dev/null 2>&1; then
                    echo -e "${GREEN}✓ minikube already installed${NC}"
                    minikube version --short 2>/dev/null || echo "installed"
                else
                    echo -e "${YELLOW}⚠️  minikube may have architecture issues${NC}"
                    MINIKUBE_NEEDS_REINSTALL=true
                fi
            fi
        else
            # On Intel, check if we have the wrong architecture
            if [[ "$FILE_ARCH" == "arm64" ]]; then
                echo -e "${YELLOW}⚠️  Wrong architecture detected (arm64 on Intel)${NC}"
                MINIKUBE_NEEDS_REINSTALL=true
            elif [[ "$FILE_ARCH" == "x86_64" ]] || [[ "$FILE_ARCH" == "amd64" ]]; then
                echo -e "${GREEN}✓ minikube already installed (Intel)${NC}"
                minikube version --short 2>/dev/null || echo "installed"
            else
                echo -e "${GREEN}✓ minikube already installed${NC}"
                minikube version --short 2>/dev/null || echo "installed"
            fi
        fi
    else
        echo -e "${YELLOW}⚠️  minikube command found but binary not accessible${NC}"
        MINIKUBE_NEEDS_REINSTALL=true
    fi
    
    if [ "$MINIKUBE_NEEDS_REINSTALL" = true ]; then
        echo "Reinstalling minikube for correct architecture..."
        brew uninstall minikube 2>/dev/null || true
        # Remove any existing minikube binary
        rm -f "$MINIKUBE_PATH" 2>/dev/null || true
        
        # Check Homebrew installation path (native ARM64 is in /opt/homebrew)
        BREW_PATH=$(which brew)
        if [[ "$ARCH" == "arm64" ]] && [[ "$BREW_PATH" == *"/usr/local"* ]]; then
            echo -e "${YELLOW}⚠️  Warning: Homebrew found in /usr/local (Intel/Rosetta version)${NC}"
            echo "For Apple Silicon, Homebrew should be in /opt/homebrew"
            echo ""
            echo "Attempting to use native ARM64 Homebrew or download directly..."
            
            # Try to use the correct Homebrew if it exists
            if [ -f "/opt/homebrew/bin/brew" ]; then
                echo "Using native ARM64 Homebrew from /opt/homebrew..."
                /opt/homebrew/bin/brew install minikube
                echo -e "${GREEN}✓ minikube reinstalled for Apple Silicon${NC}"
            else
                # Download minikube directly for ARM64
                echo "Downloading minikube directly for ARM64..."
                MINIKUBE_VERSION=$(curl -s https://api.github.com/repos/kubernetes/minikube/releases/latest | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/' || echo "v1.37.0")
                curl -LO "https://github.com/kubernetes/minikube/releases/download/${MINIKUBE_VERSION}/minikube-darwin-arm64" 2>/dev/null
                if [ -f "minikube-darwin-arm64" ]; then
                    chmod +x minikube-darwin-arm64
                    # Try to move to a location in PATH
                    INSTALLED=false
                    if [ -w "/usr/local/bin" ]; then
                        mv minikube-darwin-arm64 /usr/local/bin/minikube && INSTALLED=true
                    elif [ -w "$HOME/.local/bin" ]; then
                        mkdir -p "$HOME/.local/bin"
                        mv minikube-darwin-arm64 "$HOME/.local/bin/minikube" && INSTALLED=true
                        export PATH="$HOME/.local/bin:$PATH"
                    else
                        sudo mv minikube-darwin-arm64 /usr/local/bin/minikube && INSTALLED=true || mv minikube-darwin-arm64 /usr/local/bin/minikube && INSTALLED=true
                    fi
                    
                    if [ "$INSTALLED" = true ]; then
                        echo -e "${GREEN}✓ minikube installed directly (ARM64)${NC}"
                    else
                        rm -f minikube-darwin-arm64
                        echo -e "${RED}✗ Failed to install minikube${NC}"
                        echo "Please install minikube manually:"
                        echo "  brew install minikube (using native ARM64 Homebrew)"
                        echo "  Or download from: https://github.com/kubernetes/minikube/releases"
                        exit 1
                    fi
                else
                    echo -e "${RED}✗ Failed to download minikube${NC}"
                    echo "Please install minikube manually:"
                    echo "  brew install minikube (using native ARM64 Homebrew)"
                    echo "  Or download from: https://github.com/kubernetes/minikube/releases"
                    exit 1
                fi
            fi
        else
            if [[ "$ARCH" == "arm64" ]]; then
                echo "Installing minikube for Apple Silicon (ARM64)..."
                brew install minikube
                echo -e "${GREEN}✓ minikube reinstalled for Apple Silicon${NC}"
            else
                echo "Installing minikube for Intel (x86_64)..."
                brew install minikube
                echo -e "${GREEN}✓ minikube reinstalled for Intel${NC}"
            fi
        fi
        minikube version --short 2>/dev/null || echo "installed"
    fi
else
    echo -e "${YELLOW}Installing minikube...${NC}"
    
    # Check Homebrew installation path
    BREW_PATH=$(which brew)
    if [[ "$ARCH" == "arm64" ]] && [[ "$BREW_PATH" == *"/usr/local"* ]]; then
        echo -e "${YELLOW}⚠️  Warning: Homebrew found in /usr/local (Intel/Rosetta version)${NC}"
        echo "For Apple Silicon, Homebrew should be in /opt/homebrew"
        echo ""
        echo "Attempting to use native ARM64 Homebrew or download directly..."
        
        # Try to use the correct Homebrew if it exists
        if [ -f "/opt/homebrew/bin/brew" ]; then
            echo "Using native ARM64 Homebrew from /opt/homebrew..."
            /opt/homebrew/bin/brew install minikube
            echo -e "${GREEN}✓ minikube installed (ARM64)${NC}"
        else
            # Download minikube directly for ARM64
            echo "Downloading minikube directly for ARM64..."
            MINIKUBE_VERSION=$(curl -s https://api.github.com/repos/kubernetes/minikube/releases/latest | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/' || echo "v1.37.0")
            curl -LO "https://github.com/kubernetes/minikube/releases/download/${MINIKUBE_VERSION}/minikube-darwin-arm64" 2>/dev/null
            if [ -f "minikube-darwin-arm64" ]; then
                chmod +x minikube-darwin-arm64
                # Try to move to a location in PATH
                INSTALLED=false
                if [ -w "/usr/local/bin" ]; then
                    mv minikube-darwin-arm64 /usr/local/bin/minikube && INSTALLED=true
                elif [ -w "$HOME/.local/bin" ]; then
                    mkdir -p "$HOME/.local/bin"
                    mv minikube-darwin-arm64 "$HOME/.local/bin/minikube" && INSTALLED=true
                    export PATH="$HOME/.local/bin:$PATH"
                else
                    sudo mv minikube-darwin-arm64 /usr/local/bin/minikube && INSTALLED=true || mv minikube-darwin-arm64 /usr/local/bin/minikube && INSTALLED=true
                fi
                
                if [ "$INSTALLED" = true ]; then
                    echo -e "${GREEN}✓ minikube installed directly (ARM64)${NC}"
                else
                    rm -f minikube-darwin-arm64
                    echo -e "${RED}✗ Failed to install minikube${NC}"
                    echo "Please install minikube manually:"
                    echo "  brew install minikube (using native ARM64 Homebrew)"
                    echo "  Or download from: https://github.com/kubernetes/minikube/releases"
                    exit 1
                fi
            else
                echo -e "${RED}✗ Failed to download minikube${NC}"
                echo "Please install minikube manually:"
                echo "  brew install minikube (using native ARM64 Homebrew)"
                echo "  Or download from: https://github.com/kubernetes/minikube/releases"
                exit 1
            fi
        fi
    else
        if [[ "$ARCH" == "arm64" ]]; then
            echo "Installing minikube for Apple Silicon (ARM64)..."
        else
            echo "Installing minikube for Intel (x86_64)..."
        fi
        brew install minikube
        echo -e "${GREEN}✓ minikube installed${NC}"
    fi
    minikube version --short 2>/dev/null || echo "installed"
fi
echo ""

# Check Docker
echo "Checking Docker..."
if command -v docker &> /dev/null; then
    # Docker is installed, check if it's running
    if is_docker_running; then
        echo -e "${GREEN}✓ Docker is installed and running${NC}"
        docker --version
    else
        echo -e "${YELLOW}⚠️  Docker is installed but not running${NC}"
        echo "Starting Docker Desktop..."
        if [ -d "/Applications/Docker.app" ]; then
            open -a Docker || open "/Applications/Docker.app" || true
        else
            echo -e "${YELLOW}⚠️  Docker Desktop app not found in Applications${NC}"
            echo "Please start Docker Desktop manually from Applications or Spotlight."
        fi
        if wait_for_docker; then
            docker --version
        else
            echo -e "${YELLOW}Docker Desktop may need initial setup.${NC}"
            echo ""
            echo "Next steps:"
            echo "  1. Open Docker Desktop from Applications"
            echo "  2. Accept terms and conditions"
            echo "  3. Grant system permissions if prompted"
            echo "  4. Wait for Docker to start (you'll see the whale icon in the menu bar)"
            echo "  5. Run this script again: make install-prereqs"
            echo ""
            echo -e "${YELLOW}Exiting - please complete Docker setup and try again.${NC}"
            exit 1
        fi
    fi
elif [ -d "/Applications/Docker.app" ]; then
    # Docker.app exists but CLI not available - try to start it
    echo -e "${YELLOW}Docker Desktop found but CLI not available${NC}"
    echo "Starting Docker Desktop..."
    open -a Docker || open "/Applications/Docker.app" || true
    if wait_for_docker; then
        docker --version
    else
        echo -e "${YELLOW}Docker Desktop may need initial setup.${NC}"
        echo ""
        echo "Next steps:"
        echo "  1. Open Docker Desktop from Applications"
        echo "  2. Accept terms and conditions"
        echo "  3. Grant system permissions if prompted"
        echo "  4. Wait for Docker to start (you'll see the whale icon in the menu bar)"
        echo "  5. Run this script again: make install-prereqs"
        echo ""
        echo -e "${YELLOW}Exiting - please complete Docker setup and try again.${NC}"
        exit 1
    fi
else
    echo -e "${YELLOW}Docker not found${NC}"
    
    # Check if Homebrew thinks docker cask is installed but app is missing
    if brew list --cask docker &>/dev/null; then
        echo "Homebrew shows docker cask installed but app is missing. Reinstalling..."
        brew uninstall --cask docker --force 2>/dev/null || true
    fi
    
    echo "Installing Docker Desktop..."
    
    # Detect architecture
    ARCH=$(uname -m)
    echo "Detected architecture: $ARCH"
    
    # Check if running under Rosetta (Intel emulation on Apple Silicon)
    if [[ "$ARCH" == "arm64" ]]; then
        # Check if we're running under Rosetta
        if sysctl -n sysctl.proc_translated &>/dev/null && [[ $(sysctl -n sysctl.proc_translated) == "1" ]]; then
            echo -e "${YELLOW}⚠️  Warning: Running under Rosetta emulation${NC}"
            echo "This may cause Docker to install the wrong architecture."
            echo "Please run this script natively (not under Rosetta)."
            echo ""
        fi
        
        # Check Homebrew installation path (native ARM64 is in /opt/homebrew)
        BREW_PATH=$(which brew)
        if [[ "$BREW_PATH" == *"/usr/local"* ]]; then
            echo -e "${YELLOW}⚠️  Warning: Homebrew found in /usr/local (may be Intel/Rosetta)${NC}"
            echo "For Apple Silicon, Homebrew should be in /opt/homebrew"
            echo "This may cause the wrong Docker version to be installed."
            echo ""
        fi
        
        echo "Installing Docker Desktop for Apple Silicon (ARM64)..."
        echo "This may take a few minutes..."
        
        # Try to install with explicit architecture check
        if brew install --cask docker; then
            echo -e "${GREEN}✓ Docker Desktop installed (ARM64)${NC}"
        else
            echo -e "${RED}✗ Failed to install Docker Desktop via Homebrew${NC}"
            echo ""
            echo "Please install Docker Desktop manually:"
            echo "  Download ARM64 version: https://desktop.docker.com/mac/main/arm64/Docker.dmg"
            echo "  Or ensure Homebrew is running natively (not under Rosetta) and try:"
            echo "    brew install --cask docker"
            exit 1
        fi
    else
        echo "Installing Docker Desktop for Intel (x86_64)..."
        echo "This may take a few minutes..."
        if brew install --cask docker; then
            echo -e "${GREEN}✓ Docker Desktop installed (Intel)${NC}"
        else
            echo -e "${RED}✗ Failed to install Docker Desktop${NC}"
            echo ""
            echo "Please install Docker Desktop manually:"
            echo "  Download Intel version: https://desktop.docker.com/mac/main/amd64/Docker.dmg"
            echo "  Or try: brew install --cask docker"
            exit 1
        fi
    fi
    
    echo ""
    echo "Waiting for Docker Desktop to be available..."
    # Wait a moment for Homebrew to finish moving the app to Applications
    max_wait=10
    waited=0
    while [ $waited -lt $max_wait ] && [ ! -d "/Applications/Docker.app" ]; do
        sleep 1
        waited=$((waited + 1))
    done
    
    echo "Starting Docker Desktop..."
    if [ -d "/Applications/Docker.app" ]; then
        open -a Docker || open "/Applications/Docker.app" || true
    else
        echo -e "${YELLOW}⚠️  Docker Desktop app not found in Applications yet${NC}"
        echo "This may happen if Homebrew is still installing. Please start Docker Desktop manually:"
        echo "  - Open Applications folder and launch Docker"
        echo "  - Or use Spotlight to search for 'Docker'"
        # Don't fail the script, just continue
    fi
    echo ""
    echo -e "${YELLOW}NOTE: You may need to:${NC}"
    echo "  - Accept Docker Desktop terms and conditions"
    echo "  - Grant system permissions if prompted"
    echo ""
    if wait_for_docker; then
        docker --version
    else
        echo -e "${YELLOW}Docker Desktop may need initial setup.${NC}"
        echo ""
        echo "Next steps:"
        echo "  1. Open Docker Desktop from Applications"
        echo "  2. Accept terms and conditions"
        echo "  3. Grant system permissions if prompted"
        echo "  4. Wait for Docker to start (you'll see the whale icon in the menu bar)"
        echo "  5. Run this script again: make install-prereqs"
        echo ""
        echo -e "${YELLOW}Exiting - please complete Docker setup and try again.${NC}"
        exit 1
    fi
fi
echo ""

# Check and install Node.js
echo "Checking Node.js..."
ARCH=$(uname -m)
if command -v node &> /dev/null; then
    NODE_VERSION=$(node --version | sed 's/v//' | cut -d. -f1)
    if [ "$NODE_VERSION" -ge 20 ] 2>/dev/null; then
        echo -e "${GREEN}✓ Node.js already installed${NC}"
        node --version
    else
        echo -e "${YELLOW}⚠️  Node.js version is below 20 (found v${NODE_VERSION})${NC}"
        echo "Installing Node.js 20..."
        brew install node@20
        # Add to PATH based on architecture
        if [[ "$ARCH" == "arm64" ]]; then
            export PATH="/opt/homebrew/opt/node@20/bin:$PATH"
        else
            export PATH="/usr/local/opt/node@20/bin:$PATH"
        fi
        echo -e "${GREEN}✓ Node.js 20 installed${NC}"
        node --version
    fi
else
    echo -e "${YELLOW}Installing Node.js 20...${NC}"
    brew install node@20
    # Add to PATH based on architecture
    if [[ "$ARCH" == "arm64" ]]; then
        export PATH="/opt/homebrew/opt/node@20/bin:$PATH"
    else
        export PATH="/usr/local/opt/node@20/bin:$PATH"
    fi
    echo -e "${GREEN}✓ Node.js 20 installed${NC}"
    node --version
fi
echo ""

# Check and install npm (usually comes with Node.js, but verify)
echo "Checking npm..."
if command -v npm &> /dev/null; then
    echo -e "${GREEN}✓ npm already installed${NC}"
    npm --version
else
    echo -e "${YELLOW}Installing npm...${NC}"
    # npm should come with Node.js, but if not, install it
    if command -v node &> /dev/null; then
        # npm should be available, try to verify
        if ! npm --version &>/dev/null; then
            brew install npm
        fi
    else
        brew install npm
    fi
    echo -e "${GREEN}✓ npm installed${NC}"
    npm --version
fi
echo ""

# Check and install envsubst (part of gettext)
echo "Checking envsubst..."
if command -v envsubst &> /dev/null; then
    echo -e "${GREEN}✓ envsubst already installed${NC}"
else
    echo -e "${YELLOW}Installing envsubst (via gettext)...${NC}"
    brew install gettext
    # Add gettext to PATH if needed based on architecture
    if [[ "$ARCH" == "arm64" ]]; then
        export PATH="/opt/homebrew/opt/gettext/bin:$PATH"
    else
        export PATH="/usr/local/opt/gettext/bin:$PATH"
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
elif [ -d "/Applications/Docker.app" ]; then
    echo -e "${YELLOW}⚠️  Docker: Installed but not running${NC}"
    echo "   Docker Desktop is installed but needs to be started."
    echo "   Please open Docker Desktop from Applications and complete initial setup."
    ALL_GOOD=false
else
    echo -e "${RED}✗ Docker: Not found${NC}"
    ALL_GOOD=false
fi

if command -v kubectl &> /dev/null; then
    echo -e "${GREEN}✓ kubectl:${NC} $(kubectl version --client 2>/dev/null || kubectl version --client --short 2>/dev/null || echo 'installed')"
else
    echo -e "${RED}✗ kubectl: Not found${NC}"
    ALL_GOOD=false
fi

if command -v minikube &> /dev/null; then
    MINIKUBE_VER=$(minikube version --short 2>/dev/null || echo 'installed')
    ARCH=$(uname -m)
    MINIKUBE_PATH=$(which minikube)
    ARCH_MISMATCH=false
    
    if [ -f "$MINIKUBE_PATH" ]; then
        FILE_ARCH=$(file "$MINIKUBE_PATH" 2>/dev/null | grep -o "arm64\|x86_64\|amd64" | head -1 || echo "")
        
        if [[ "$ARCH" == "arm64" ]]; then
            if [[ "$FILE_ARCH" == "x86_64" ]] || [[ "$FILE_ARCH" == "amd64" ]]; then
                ARCH_MISMATCH=true
            fi
        else
            if [[ "$FILE_ARCH" == "arm64" ]]; then
                ARCH_MISMATCH=true
            fi
        fi
    fi
    
    if [ "$ARCH_MISMATCH" = true ]; then
        echo -e "${RED}✗ minikube: Architecture mismatch (run script again to fix)${NC}"
        ALL_GOOD=false
    elif ! minikube version --short &> /dev/null; then
        echo -e "${RED}✗ minikube: Architecture mismatch or not working${NC}"
        ALL_GOOD=false
    else
        ARCH_LABEL=""
        if [[ "$ARCH" == "arm64" ]]; then
            ARCH_LABEL=" (ARM64)"
        else
            ARCH_LABEL=" (Intel)"
        fi
        echo -e "${GREEN}✓ minikube:${NC} $MINIKUBE_VER$ARCH_LABEL"
    fi
else
    echo -e "${RED}✗ minikube: Not found${NC}"
    ALL_GOOD=false
fi

if command -v node &> /dev/null; then
    echo -e "${GREEN}✓ Node.js:${NC} $(node --version)"
else
    echo -e "${RED}✗ Node.js: Not found${NC}"
    ALL_GOOD=false
fi

if command -v npm &> /dev/null; then
    echo -e "${GREEN}✓ npm:${NC} $(npm --version)"
else
    echo -e "${RED}✗ npm: Not found${NC}"
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
    echo "  1. Make sure Docker Desktop is running"
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

