function New-VirtJunkieLinkedClone {
    [CmdletBinding()]
    <#
    Github: https://github.com/jonhowe/Virtjunkie.com/blob/master/Deploy-VM.ps1
    Link: https://www.virtjunkie.com/?p=774
    #>
    param (
        #vCenter Info
        $vCenter            = 'vcsa.home.lab',
        $username           = 'administrator@vsphere.local',
        $password           = 'VMWare1!',
        $TemplateCustomSpec = 'linux',
        #$TemplateCustomSpec = 'WS16to19',

        #Parent VM Info
        $ParentVMName       = 'PhotonOS',
        $SnapshotName       = "Base",

        #New VM Info
        $VMName             = "Photon-1",
        $VMIP               = "192.168.86.216",
        $VMNetmask          = "255.255.255.0",
        $VMGateway          = "192.168.86.1",
        $VMDNS              = "192.168.86.232"
    )
    
    begin {
        $vc_conn = Connect-VIServer -Server $vCenter -User $username -Password $password
    }
    
    process {
        # Get the OS CustomizationSpec and clone
        $OSCusSpec = Get-OSCustomizationSpec -Name $TemplateCustomSpec | 
            New-OSCustomizationSpec -Name 'tempcustomspec' -Type NonPersistent

        #Update Spec with IP information
        switch ($OSCusSpec.OSType) {
            Linux 
            {  
                Get-OSCustomizationNicMapping -OSCustomizationSpec $OSCusSpec |
                Set-OSCustomizationNicMapping -IPMode UseStaticIP `
                    -IPAddress $VMIP `
                    -SubnetMask $VMNetmask  `
                    -DefaultGateway $VMGateway `
            }
            Windows 
            {  
                Get-OSCustomizationNicMapping -OSCustomizationSpec $OSCusSpec |
                Set-OSCustomizationNicMapping -IPMode UseStaticIP `
                    -IPAddress $VMIP `
                    -SubnetMask $VMNetmask  `
                    -DefaultGateway $VMGateway `
                    -Dns $VMDNS
            }
            Default 
            {
                Throw "No valid OS Type in custom spec"
            }
        }
 

        $mySourceVM = Get-VM -Name $ParentVMName
        $myReferenceSnapshot = Get-Snapshot -VM $mySourceVM -Name $SnapshotName 
        $Cluster = Get-Cluster 'Cluster'
        $myDatastore = Get-Datastore -Name 'Shared'

        $rs = New-VM -Name $VMName -VM $mySourceVM -LinkedClone -ReferenceSnapshot $myReferenceSnapshot -ResourcePool $Cluster `
        -Datastore $myDatastore -OSCustomizationSpec $OSCusSpec
    }
    
    end {
        Get-OSCustomizationSpec -Name $OSCusSpec | Remove-OSCustomizationSpec -Confirm:$false
        return $rs
    }
}

New-VirtJunkieLinkedClone