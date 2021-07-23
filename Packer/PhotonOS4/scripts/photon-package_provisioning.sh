#!/bin/sh

#upgrade packages
tdnf check-update
tdnf --assumeyes upgrade
#install python3 and ansible
tdnf --assumeyes install ansible python3
