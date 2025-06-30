#!/usr/bin/env bash

# Adjust version as needed
VERSION=1.4.1
URL_BASE="https://github.com/apptainer/apptainer/releases/download/v${VERSION}"

# Install dependencies for apptainer
if which apt > /dev/null 2>&1; then
  # System is Debian based
  echo Install Apptainer for Debian based system
  sudo apt update -q
  PKG_INSTALL_CMD=apt install -y
  PKG="apptainer_${VERSION}_amd64.deb"
elif which dnf > /dev/null 2>&1; then
  # System is RHEL based
  echo Install Apptainer for RHEL based system
  PKG_INSTALL_CMD=dnf install -y
  PKG="apptainer-${VERSION}-1.x86_64.rpm"
elif which pacman > /dev/null 2>&1; then
  # System is Arch based
  echo Install Apptainer for Arch based system
  # available in https://archlinux.org/packages/extra/x86_64/apptainer/
  sudo pacman -Syu apptainer
  exit 0
elif which nix-shell > /dev/null 2>&1; then
  echo 'run one of these commands:'
  echo '  nix-shell -p apptainer'
  echo '  nix-env -iA nixos.apptainer  # not recommended'
  echo 'or add this to your config and rebuild:'
  echo '  environment.systemPackages = ['
  echo '    pkgs.apptainer'
  echo '  ];'
  exit 0
else
  echo Can only install Apptainer on Debian, RHEL, Arch or NixOS based systems
  exit 1
fi

# Move to tmp dir
old_dir=$(pwd)
cd /tmp

# Install wget and download package
sudo $PKG_INSTALL_CMD wget
wget "$URL_BASE/$PKG"

# Install the package
sudo $PKG_INSTALL_CMD "./$PKG"
rm "$PKG"

# Restore original dir
cd "$old_dir"
unset old_dir
