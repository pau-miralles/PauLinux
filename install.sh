#!/usr/bin/env bash
set -e

echo "Enable Flakes"
mkdir -p ~/.config/nix
echo "experimental-features = nix-command flakes" >> ~/.config/nix/nix.conf

echo "Clone Repo"
rm -rf "$HOME/.nixos-config"
nix-shell -p git --run "git clone https://github.com/pau-miralles/PauLinux.git ~/.nixos-config"

echo "Generate hardware-configuration"
sudo nixos-generate-config --show-hardware-config > ~/.nixos-config/hardware-configuration.nix
cd ~/.nixos-config

echo "Refresh flake.lock"
rm -f flake.lock
nix-shell -p git --run "git add . && nix flake update"

echo "Rebuild"
sudo nixos-rebuild switch --flake .#framework

echo "DONE!"
read -n 1 -s -r -p "Press any key to reboot: "
sudo reboot
