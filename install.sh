#!/usr/bin/env bash
set -e

echo "Enable Flakes"
mkdir -p ~/.config/nix
echo "experimental-features = nix-command flakes" >> ~/.config/nix/nix.conf

echo "Clone Repo"
if [ -d "$HOME/.nixos-config" ]; then
    rm "$HOME/.nixos-config" # idk if putting it without the if would give an eror that set -e would pick up and exit
fi
git clone https://github.com/pau-miralles/PauLinux.git ~/.nixos-config

echo "Generate hardware-configuration"
sudo nixos-generate-config --show-hardware-config > ~/.nixos-config/hardware-configuration.nix

cd ~/.nixos-config
git add .

echo "Refresh flake.lock"
rm -f flake.lock
nix flake update

echo "Rebuild"
sudo nixos-rebuild switch --flake .#framework

echo "DONE!"
