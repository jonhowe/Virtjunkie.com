<#
.LINK http://www.virtjunkie.com/powershell-parse-rvtools/
.LINK https://github.com/jonhowe/Virtjunkie.com/blob/master/Parse-RVTools-Generic.ps1
#>
param(
    # Migrate Powered Off VMs?
    [switch]$IncludePoweredOffVMs,

    # Directory that contains RVTools Exports
    $spreadsheetdir = "/path/to/RVTools",
    
    # Array that contains column headers to be gathered from the vHost worksheet
    $vHostProperties = @(
        'Host', 
        "CPU usage %",
        "Memory usage %",
        'model',
        "Service Tag",
        "Current EVC",
        "Max EVC",
        "# VMs",
        "# Memory",
        "# Cores",
        "HT Active",
        "vCPUs per Core"
    ),

    # Array that contains column headers to be gathered from the vInfo worksheet
    $vInfoProperties = @(
        'VM',
        'Template',
        "HW version",
        "Provisioned MB",
        "In Use MB",
        "OS according to the VMware Tools",
        'memory'
    ),

    # Array that contains column headers to be gathered from the vDisk worksheet
    $vDiskProperties = @(
        "vm",
        "Raw LUN ID",
        "Raw Comp. Mode",
        "Shared Bus"
    )

)

# Get all spreadsheets in the spreadsheet directory
$spreadsheets = $spreadsheetdir | Get-ChildItem

$rs = @()
# Loop through all spreadsheets in the spreadsheet dir
foreach ($sheet in $SpreadSheets)
{
    # Use the importexcel module to import the vCluster Worksheet
    # We do this as an easy way to get the 
    $vCluster = Import-Excel -Path $sheet -Sheet vCluster
    
    foreach ($cluster in $vCluster)
    {
        $ClusterDetails = New-Object System.Object
        $ClusterDetails | Add-Member -type NoteProperty -name vCenter -Value ($cluster."VI SDK Server")
        $ClusterDetails | Add-Member -type NoteProperty -name Cluster -Value $cluster.name 
       
        # Parse and store the properties defined in the $vInfoProperties array
        #   from the vInfo tab
        $vInfo = Import-Excel -Path $sheet -WorksheetName vInfo | 
            Where-Object { $_.Cluster -eq $cluster.name } | 
            Select-Object $vInfoProperties

        # Parse and store the properties defined in the $vHostProperties array
        #   from the vHost tab
        $vHost = Import-Excel -Path $sheet -WorksheetName vHost | 
            Where-Object { $_.Cluster -eq $cluster.name } | 
            Select-Object $vHostProperties

        # Parse and store the properties defined in the $vDiskProperties array
        #   from the vDisk tab
        $vDisk = Import-Excel -Path $sheet -WorksheetName vDisk | 
            Where-Object {$_.Cluster -eq $cluster.name } | 
            Select-Object $vDiskProperties

        # Calculate the sum of the column Provisioned MB from all rows in the vInfo tab, convert to GB, and round
        $TotalProvisionedGB = [math]::round(($vInfo | Measure-Object -Sum "Provisioned MB").Sum / 1024, 2)
        $ClusterDetails | Add-Member -type NoteProperty -name TotalProvisionedGB -Value $TotalProvisionedGB        

        # Calculate the sum of the column In Use MB from all rows in the vInfo tab, convert to GB, and round
        $TotalInUseGB = [math]::round(($vInfo | Measure-Object -Sum "In Use MB").Sum / 1024, 2)
        $ClusterDetails | Add-Member -type NoteProperty -name TotalInUseGB -Value $TotalInUseGB
        
        # Calculate average vCPU to PCPU, the total RAM in the cluster, and the average RAM Usage
        $vCPUtoPCPU = [math]::round(($vHost | Measure-Object -Average "vCPUs per Core").average, 2)
        $clusterRAM = [math]::round(($vHost | Measure-Object -Sum "# Memory").Sum / 1024, 2)
        $AvgClusterRamUsage = [math]::round(($vHost | Measure-Object -Average "Memory Usage %").average, 2)

        #Detect RDMs and VMs with Shared Bus based on info in the vDisk sheet
        $RDMs = ($vDisk | ? { $_."Raw LUN ID" -ne $null})
        $SharedBusVMs = ($vDisk | ? { $_."Shared Bus" -ne $null -and $_."Shared Bus" -ne "noSharing" -and $_."Shared Bus" -ne 0})

        $clusterCoreCount = [math]::round(($cluster | Measure-Object -Sum "NumCpuCores").sum,0)

        $ClusterDetails | Add-Member -type NoteProperty -name AvgClusterRamUsage -Value $AvgClusterRamUsage
        $ClusterDetails | Add-Member -type NoteProperty -name ClusterRamGB -Value $clusterRAM
        $ClusterDetails | Add-Member -type NoteProperty -name ClusterVMCount -Value $vInfo.count
        $ClusterDetails | Add-Member -type NoteProperty -name ClusterHostCount -Value ($vHost.count)
        $ClusterDetails | Add-Member -type NoteProperty -name TotalClusterCores -Value $clusterCoreCount
        $ClusterDetails | Add-Member -type NoteProperty -name vCPUtoPCPU -Value ($vCPUtoPCPU)
        $ClusterDetails | Add-Member -type NoteProperty -name RDMCount -Value ($RDMs.count)
        $ClusterDetails | Add-Member -type NoteProperty -name SharedBusVMs -Value ($SharedBusVMs.count)
        
        $rs += $ClusterDetails
    }
}

$rs