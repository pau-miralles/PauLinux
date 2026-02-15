#!/usr/bin/env bash

# Colors
GREEN='\033[0;32m'
NC='\033[0m' # No Color

echo -e "${GREEN}Starting PauLinux Setup...${NC}"

# 1. Enable Flakes (Just in case)
mkdir -p ~/.config/nix
echo "experimental-features = nix-command flakes" >> ~/.config/nix/nix.conf

# 2. Backup existing /etc/nixos
if [ -d "/etc/nixos" ]; then
    echo -e "${GREEN}Backing up existing /etc/nixos...${NC}"
    sudo mv /etc/nixos /etc/nixos.bak
fi

# 3. Clone the Repo (if not already there)
if [ -d "$HOME/.nixos-config" ]; then
    echo -e "${GREEN}Repo already exists in home, pulling latest...${NC}"
    cd ~/nixos-config
    git pull
else
    echo -e "${GREEN}Cloning configuration...${NC}"
    # Using HTTPS so we don't need SSH keys yet
    git clone https://github.com/pau-miralles/PauLinux.git ~/.nixos-config
fi

# 4. Generate Hardware Config for THIS machine
echo -e "${GREEN}Generating hardware-configuration.nix...${NC}"
sudo nixos-generate-config --show-hardware-config > ~/.nixos-config/hardware-configuration.nix

# 5. Link /etc/nixos to Home
echo -e "${GREEN}Symlinking /etc/nixos -> ~/.nixos-config...${NC}"
sudo ln -sfn ~/.nixos-config /etc/nixos

# 6. Fix lock file (Crucial for fresh installs)
cd ~/.nixos-config
echo -e "${GREEN}Updating flake lock file...${NC}"
nix flake update

# 7. Rebuild
echo -e "${GREEN}Rebuilding System...${NC}"
# We use 'framework' because that is the name in your flake.nix
sudo nixos-rebuild switch --flake .#framework

echo -e "${GREEN}DONE! Please reboot now.${NC}"
