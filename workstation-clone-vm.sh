#Original Locations:
#Blog: http://www.virtjunkie.com/thin-provision-vms-on-workstation-pro-using-the-vmrun-command/
#Github: https://github.com/jonhowe/Virtjunkie.com/blob/master/workstation-clone-vm.sh

#Example:
#testgetopt.sh --user root --pass [pass] --template /storage/virtual_machines/Ubuntu_1810_Template/Ubuntu_1810_Template.vmx --snapshot base-4 --name test1

TEMP=`getopt -o u:,p:,n:,t:,s: --long user:,pass:,name:,template:,snapshot: -n 'clone_workstation_vm' -- "$@"`

if [ $? != 0 ] ; then echo "Terminating..." >&2 ; exit 1 ; fi

eval set -- "$TEMP"

VMRUN=/usr/bin/vmrun



#Do not edit below this line
SOURCEVM=
SOURCESNAPSHOT=
DESTINATIONVMNAME=
GUESTUSER=
GUESTPASS=
echo "Parameters are:"
while true; do
  case "$1" in
    -u | --user )
        GUESTUSER=$2;echo "User=$GUESTUSER"; shift 2 ;;
    -p | --pass )
        GUESTPASS=$2;echo "Pass=$GUESTPASS"; shift 2 ;;
    -n | --name )
        DESTINATIONVMNAME=$2;echo "New VM Name=$DESTINATIONVMNAME"; shift 2 ;;
    -s | --snapshot )
        SOURCESNAPSHOT=$2;echo "Snapshot Name=$SOURCESNAPSHOT"; shift 2 ;;
    -t | --template )
        SOURCEVM=$2;echo "Template Name=$SOURCEVM"; shift 2 ;;
    -- ) shift; break ;;
    * ) break ;;
  esac
done
echo

wait_for_vmware_tools() {
    CMD=$1
    USER=$2
    PASS=$3
    VM=$4
    echo "Waiting for VMware Tools to start"
    until ($CMD -T ws -gu $USER -gp $PASS CheckToolsState $VM | grep -q "running"); do 
        printf '.'
        sleep 5;
    done
    sleep 10
    echo
}

wait_for_vm_ip() {
    CMD=$1
    USER=$2
    PASS=$3
    VM=$4
    echo "Waiting for the VM to return an IP Address"
    until ($CMD -t ws -gu $USER -gp $PASS getGuestIPAddress $VM | grep -q -v "Error: Unable to get the IP address"); do
        printf "."
        sleep 5
    done
    sleep 10
    echo

    IP="$($CMD -t ws -gu $USER -gp $PASS getGuestIPAddress $VM)"
    echo "VM is running and has the IP Address: $IP"
    echo
}

clone_workstation_vm() {
    SOURCE=$1
    DESTINATION=$2
    SNAPSHOT=$3
    USER=$4
    PASS=$5

    SOURCEVMX="${SOURCE##*/}"
    SOURCEVMNAME="${SOURCEVMX%%.*}"
    NEWVM=/storage/virtual_machines/$DESTINATION/$DESTINATION.vmx

    echo "Cloning $SOURCEVMNAME to $DESTINATION and using the snapshot: $SNAPSHOT"
    $VMRUN -T ws -gu $USER -gp $PASS clone $SOURCE $NEWVM linked $SNAPSHOT

    sed -i "s/displayName = \"Clone of $SOURCEVMNAME\"/displayName = \"$DESTINATION\"/g" $NEWVM

    echo "Powering on $DESTINATION"
    $VMRUN -t ws -gu $USER -gp $PASS start $NEWVM

    wait_for_vmware_tools $VMRUN $USER $PASS $NEWVM

    echo "Copying script to change the hostname from the host to the guest"
    currentDir="${0%/*}"
    $VMRUN -t ws -gu $USER -gp $PASS copyFileFromHostToGuest $NEWVM $currentDir"/JH01_Set-Hostname.sh" /tmp/JH01_Set-Hostname.sh
    echo "Running custom script in $DESTINATION to set the hostname and rebooting"
    $VMRUN -t ws -gu $USER -gp $PASS runProgramInGuest $NEWVM /tmp/JH01_Set-Hostname.sh "$DESTINATION"

    wait_for_vmware_tools $VMRUN $USER $PASS $NEWVM

    echo "Copying output to local machine"
    $VMRUN -t ws -gu $USER -gp $PASS copyFileFromGuestToHost $NEWVM /var/log/oscustomization.log $currentDir"/"$DESTINATION"_Customization.log"
    echo
    echo "Below is the output from the OS Customization:"
    cat $currentDir"/"$DESTINATION"_Customization.log"

    wait_for_vm_ip $VMRUN $USER $PASS $NEWVM
}

start=`date +%s`

clone_workstation_vm $SOURCEVM $DESTINATIONVMNAME $SOURCESNAPSHOT $GUESTUSER $GUESTPASS

end=`date +%s`
runtime=$((end-start))

echo "Script took $runtime seconds to execute"
