#!/bin/sh

set -x

sudo -v

# Install generic packages
sudo apt -y install \
    autoconf-archive \
    libcmocka0 \
    libcmocka-dev \
    procps \
    iproute2 \
    build-essential \
    git \
    pkg-config \
    gcc \
    libtool \
    automake \
    libssl-dev \
    uthash-dev \
    autoconf \
    doxygen \
    libjson-c-dev \
    libini-config-dev \
    libcurl4-openssl-dev \
    uuid-dev \
    pandoc \
    acl \
    libglib2.0-dev \
    xxd

# Install dependencies for the libtpms-based TPM emulator on Ubuntu-22.04.
sudo apt-get install -y \
    dh-autoreconf \
    libtasn1-6-dev \
    net-tools \
    libgnutls28-dev \
    expect \
    gawk \
    socat \
    libfuse-dev \
    libseccomp-dev \
    make \
    libjson-glib-dev \
    gnutls-bin

set -e

# Create the working folder.
mkdir -p "$HOME/tpm"

# Install tpm2-tss
git clone https://github.com/tpm2-software/tpm2-tss "$HOME/tpm/tpm2-tss"
cd "$HOME/tpm/tpm2-tss"
git checkout 3.2.0
./bootstrap
./configure
make -j$(nproc)
sudo make install
sudo ldconfig
cd "$HOME"

# Install tpm2-tools.
git clone https://github.com/tpm2-software/tpm2-tools "$HOME/tpm/tpm2-tools"
cd "$HOME/tpm/tpm2-tools"
git checkout 5.2
./bootstrap
./configure
make -j$(nproc)
sudo make install
sudo ldconfig
cd "$HOME"

# Install tpm2-abrmd.
git clone https://github.com/tpm2-software/tpm2-abrmd ~/tpm/tpm2-abrmd
cd ~/tpm/tpm2-abrmd
git checkout 2.4.1
./bootstrap
./configure
make -j$(nproc)
sudo make install
sudo ldconfig
cd ~

# Install tpm2-openssl (substitute for tpm2-tss-engine) on Ubuntu-22.04
git clone https://github.com/tpm2-software/tpm2-openssl ~/tpm/tpm2-openssl
cd ~/tpm/tpm2-openssl
git checkout 1.1.0
./bootstrap
./configure --enable-debug
make -j$(nproc)
sudo make install
sudo ldconfig
cd ~

# Install libtpms-based TPM emulator on Ubuntu-22.04.
## Install libtpms-devel
git clone https://github.com/stefanberger/libtpms ~/tpm/libtpms
cd ~/tpm/libtpms
git checkout v0.9.5
./autogen.sh --with-tpm2 --with-openssl
make -j$(nproc)
sudo make install
sudo ldconfig
cd ~

## Install Libtpms-based TPM emulator
git clone https://github.com/stefanberger/swtpm ~/tpm/swtpm
cd ~/tpm/swtpm
git checkout v0.7.3
./autogen.sh --with-openssl --prefix=/usr
make -j$(nproc)
sudo make install
sudo ldconfig
cd ~
