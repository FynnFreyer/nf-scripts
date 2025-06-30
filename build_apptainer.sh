#!/usr/bin/env bash

# According to https://github.com/apptainer/apptainer/blob/v1.4.1/INSTALL.md

# Install dependencies for apptainer
if which apt; then  # is debian based
	# Ensure repositories are up-to-date
	sudo apt-get update
	# Install debian packages for dependencies
	sudo apt-get install -y \
		build-essential \
		libseccomp-dev \
		uidmap \
		fakeroot \
		cryptsetup \
		tzdata \
		dh-apparmor \
		curl wget git
elif which dnf; then  # is RHEL based
	# Install basic tools for compiling
	sudo dnf groupinstall -y 'Development Tools'
	# Ensure EPEL repository is available
	sudo dnf install -y epel-release
	# Install RPM packages for dependencies
	sudo dnf install -y \
		libseccomp-devel \
		fakeroot \
		cryptsetup \
		wget git
elif which zypper; then  # is openSUSE based
	# Install RPM packages for dependencies
	sudo zypper install -y \
	  libseccomp-devel \
	  libuuid-devel \
	  openssl-devel \
	  fakeroot \
	  cryptsetup sysuser-tools \
	  wget git go
	# Install these before devel tools to avoid clashing busybox pkgs on Tumbleweed
	sudo zypper install -y diffutils which
	# Install basic tools for compiling
	# --replacefiles is needed to avoid pam conflict on Tumbleweed
	sudo zypper install -y --replacefiles --allow-downgrade -t pattern devel_basis
else; then
  echo Can only install Apptainer on Debian, RHEL, or openSUSE based systems
  exit 1
fi

# Go to temp dir for downloads

oldcwd=`pwd`
cd /tmp

# Install go

sudo rm -rf /usr/local/go

export VERSION=1.23.6 OS=linux ARCH=amd64 && \
    wget https://dl.google.com/go/go$VERSION.$OS-$ARCH.tar.gz && \
    sudo tar -C /usr/local -xzvf go$VERSION.$OS-$ARCH.tar.gz && \
    rm go$VERSION.$OS-$ARCH.tar.gz

echo 'export GOPATH=${HOME}/go' >> ~/.bashrc && \
echo 'export PATH=/usr/local/go/bin:${PATH}:${GOPATH}/bin' >> ~/.bashrc

source ~/.bashrc

# Checkout and install apptainer

git clone https://github.com/apptainer/apptainer.git
cd apptainer
git checkout v1.4.1

./mconfig
cd $(/bin/pwd)/builddir
make
sudo make install

cd ${oldcwd}
