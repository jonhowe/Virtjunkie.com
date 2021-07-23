#!/bin/sh

# Install VMware Tools

# Faking a sysV-based system
if [ ! -d /etc/init.d ]; then mkdir /etc/init.d; fi

tdnf -y install open-vm-tools
systemctl enable vmtoolsd.service
systemctl start vmtoolsd.service

# Install required packages.
tdnf --assumeyes install gawk
tdnf --assumeyes install make
tdnf --assumeyes install gcc
tdnf --assumeyes install tar
tdnf --assumeyes install linux-devel-$(uname -r)
tdnf --assumeyes install binutils
tdnf --assumeyes install linux-api-headers

# Remove packages
tdnf --assumeyes erase linux-api-headers
tdnf --assumeyes erase linux-devel-$(uname -r)
tdnf --assumeyes erase tar
tdnf --assumeyes erase gcc
tdnf --assumeyes erase libgcc-atomic
tdnf --assumeyes erase libgcc-devel
tdnf --assumeyes erase libgomp libgomp-devel
tdnf --assumeyes erase libstdc++-devel
tdnf --assumeyes erase mpc
tdnf --assumeyes erase make
tdnf --assumeyes erase binutils binutils-libs
tdnf --assumeyes erase m4
tdnf --assumeyes erase perl perl-DBI

# Make sure bc is still installed
tdnf --assumeyes install bc

echo "Compacting disk space"
FileSystem=`grep ext /etc/mtab| awk -F" " '{ print $2 }'`

for i in $FileSystem
do
        echo $i
        number=`df -B 512 $i | awk -F" " '{print $3}' | grep -v Used`
        echo $number
        percent=$(echo "scale=0; $number * 98 / 100" | bc )
        echo $percent
        dd count=`echo $percent` if=/dev/zero of=`echo $i`/zf
        /bin/sync
        sleep 15
        rm -f $i/zf
done

# Remove tdnf cache
rm -rf /var/cache/tdnf/*

# Remove init.d entirely if empty

if [ ! "$(ls -A /etc/init.d)" ]; then rmdir /etc/init.d; fi
