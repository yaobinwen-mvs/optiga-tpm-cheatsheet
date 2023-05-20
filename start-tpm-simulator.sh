#!/bin/sh

sudo apt install -y dbus

set -ex

mkdir /tmp/emulated_tpm

# Start Libtpms-based TPM emulator on Ubuntu-22.04:

## Create configuration files for swtpm_setup:
## - ~/.config/swtpm_setup.conf
## - ~/.config/swtpm-localca.conf
##   This file specifies the location of the CA keys and certificates:
##   - ~/.config/var/lib/swtpm-localca/*.pem
## - ~/.config/swtpm-localca.options
swtpm_setup --tpm2 --create-config-files overwrite,root

## Initialize the swtpm
swtpm_setup --tpm2 --config ~/.config/swtpm_setup.conf --tpm-state /tmp/emulated_tpm --overwrite --create-ek-cert --create-platform-cert --write-ek-cert-files /tmp/emulated_tpm

## Launch the swtpm
swtpm socket --tpm2 --flags not-need-init --tpmstate dir=/tmp/emulated_tpm --server type=tcp,port=2321 --ctrl type=tcp,port=2322 &
sleep 5

# Start TPM resource manager on a session dbus instead of system dbus

## Start a session dbus which is limited to the current login session
export DBUS_SESSION_BUS_ADDRESS=`dbus-daemon --session --print-address --fork`

## Start TPM resource manager on Ubuntu-22.04
tpm2-abrmd --allow-root --session --tcti=swtpm:host=127.0.0.1,port=2321 &
sleep 5

# Set TCTI
## for tpm2-tools
export TPM2TOOLS_TCTI="tabrmd:bus_name=com.intel.tss2.Tabrmd,bus_type=session"

## for tpm2-tss-engine (Debian Bullseye, Debian Buster, Ubuntu-18.04, Ubuntu-20.04)
export TPM2TSSENGINE_TCTI="tabrmd:bus_name=com.intel.tss2.Tabrmd,bus_type=session"

## for tpm2-openssl (Ubuntu-22.04)
export TPM2OPENSSL_TCTI="tabrmd:bus_name=com.intel.tss2.Tabrmd,bus_type=session"

# Perform TPM startup
tpm2_startup -c

# Get random (as a test)
tpm2_getrandom --hex 16