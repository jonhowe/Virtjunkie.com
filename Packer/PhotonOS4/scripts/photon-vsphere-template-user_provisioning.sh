#!/bin/sh

HOME_DIR="/home/labuser"

# Add labuser group
groupadd labuser

# Set up a vagrant user and add the insecure key for User to login
useradd -G labuser -m labuser

# Avoid password expiration (https://github.com/vmware/photon-packer-templates/issues/2)
chage -I -1 -m 0 -M 99999 -E -1 labuser
chage -I -1 -m 0 -M 99999 -E -1 root

# Configure a sudoers for the labuser user
echo "vagrant ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/labuser

# Add Docker group
groupadd docker

# Add Photon user to Docker group
usermod -a -G docker labuser

#Set password for labuser
echo -e "<passwd>\n<passwd>" | passwd jhowe