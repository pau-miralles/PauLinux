#!/usr/bin/env bash

echo "Enabling Flakes"
mkdir -p ~/.config/nix
echo "experimental-features = nix-command flakes" >> ~/.config/nix/nix.conf

echo "Removing default config"
sudo rm -rf /etc/nixos

echo "loning Repository"
git clone https://github.com/pau-miralles/PauLinux.git ~/.nixos-config

echo "Generating hardware-config"
sudo nixos-generate-config --show-hardware-config > ~/.nixos-config/hardware-configuration.nix

echo "Symlink to /etc/nixos"
sudo ln -s /home/pau/.nixos-config /etc/nixos

echo "Refreshing Flake Lock"
cd ~/.nixos-config
rm flake.lock
nix flake update

echo "Rebuild"
sudo nixos-rebuild switch --flake .#framework

echo "DONE"
