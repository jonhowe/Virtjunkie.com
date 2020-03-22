<#
.SYNOPSIS
Install the VMware vCenter Server Appliance based on input from a Microsoft Excel File

.DESCRIPTION
This script will install the VMware vCenter Server Appliance based on input from a Microsoft Excel File.

.PARAMETER ForceDownload
Switch parameter that will force a (re) download and extract of the ISO

.PARAMETER URI
This is the URL of the vCenter Installer ISO

.PARAMETER Workspace
Absolute path to the directory that will be used as a workspace. The vCenter ISO will be downloaded there, and will be
extracted there as well.

.PARAMETER DeploymentTarget
Location that the new VCSA will be deployed to.
Valid options are: ESXi, vCenter

.PARAMETER ExcelFile
Absolute path to the Excel file that contains the parameters required for vCenter to be built

.PARAMETER 7z
Absolute path path to the 7z binary
#>
#Requires -modules Microsoft.powershell.archive,importexcel
[CmdletBinding()]
param (
    [switch]$ForceDownload
    ,
    $URI = "http://jondesktop.home.lan:8123/files/VMware/VSMRepo/dlg_VC67U3B/VMware-VCSA-all-6.7.0-15132721.iso"
    ,
    [Parameter(Mandatory=$true)]
    [ValidateScript( {
            if ( -Not ($_ | Test-Path) ) {
                throw "File or folder does not exist"
            }
            return $true
        })]
    $Workspace
    ,
    [validateset("vCenter", "ESXi")]
    $deploymentTarget
    ,
    [ValidateScript( { Test-Path $_ })]
    [string]
    $ExcelFile = "/home/jhowe/git/Personal/AutomatedLab/JonAutoLab/HostDetails.xlsx"
    ,
    [ValidateScript( {
        if ( -Not ($_ | Test-Path) ) {
            throw "Path to 7zip is not correct"
        }
        return $true
    })]
    $7z = '/usr/bin/7z'
)
$ErrorActionPreference = 'Stop'

#region Download and Extract the ISO
$VCSA_Installer_Archive = $workspace + ($uri.Split('/')[-1])
$VCSA_Extracted_Directory = ($VCSA_Installer_Archive.Split(".iso")[0])
$VCSA_CLI_Installer_Path = ($VCSA_Extracted_Directory + "/vcsa-cli-installer/")

#Download the VCSA only if it doesn't already exist
if ((Test-Path $VCSA_Installer_Archive) -eq $false -or $forcedownload) {
    $filesize = (Invoke-WebRequest $uri -Method Head).Headers.'Content-Length'
    [int]$WebServerFileSize = ([convert]::ToInt64($filesize, 10)) / 1024

    Write-Output "Downloading VCSA Installer"
    $wc = New-Object System.Net.WebClient
    $wc.DownloadFileAsync($uri, $VCSA_Installer_Archive)

    #The following loop will print the progressof the download every 15 seconds
    $incomplete = $true
    while ($incomplete) {
        $CurrentSize = ((Get-Item $VCSA_Installer_Archive).length) / 1024
    
        if ($CurrentSize -eq $WebServerFileSize) {
            $incomplete = $false
        }
        else {
            Write-Output "File Download Size is $([math]::round($CurrentSize,0)) / $($WebServerFileSize) ($(($CurrentSize / $WebServerFileSize).ToString("P") )%)"
            Start-Sleep -Seconds 15
        }
    }
}
else {
    Write-Output "VCSA Installer already exists"    
}

#Extract the VCSA only if the directory it should be extracted to doesn't already exist
if ((Test-Path ($VCSA_Extracted_Directory)) -eq $false -or $forcedownload) {
    Write-Output "Unzipping VCSA"
    #Expand-Archive -LiteralPath $VCSA_Installer_Archive -destinationpath $workspace

    Write-Output "Extracting the ISO now..."
    $arguments = "x -bb0 -bd -y -o$($VCSA_Extracted_Directory) $($VCSA_Installer_Archive)"
    Write-Verbose -Message ($7z + " " + $arguments)

    $pinfo = New-Object System.Diagnostics.ProcessStartInfo
    $pinfo.FileName = $7z
    $pinfo.RedirectStandardError = $true
    $pinfo.RedirectStandardOutput = $true
    $pinfo.UseShellExecute = $false
    $pinfo.Arguments = $arguments
    $p = New-Object System.Diagnostics.Process
    $p.StartInfo = $pinfo
    $p.Start() | Out-Null
    $p.WaitForExit()
    $7z_stdout = $p.StandardOutput.ReadToEnd()
    $7z_stderr = $p.StandardError.ReadToEnd()

    $7z_stdout | out-file -Path ($workspace + "7z-stdout.txt")
    $7z_stderr | out-file -Path ($workspace + "7z-stderr.txt")

    if ($p.ExitCode -ne 0) {
        Write-Output "There was an error..."
        Write-Output "Process finished with exit code $($p.ExitCode)"
        Write-Output "Log data written to: $($workspace)7z-stdout.txt and $($workspace)7z-stderr.txt"
        $7z_stderr
    }
    else {
        Write-Output "Extraction completed successfully."
    }
}
else {
    Write-Output "VCSA has already been unzipped"
}
#endregion Download and Extract the ISO

#region import excel file into sections and validate input
$targettype = Import-Excel $excelfile -WorksheetName vCenter -StartRow 1 -EndRow 2 -StartColumn 1 -EndColumn 1
$targetinfo = Import-Excel $excelfile -WorksheetName vCenter -StartRow 1 -EndRow 2 -StartColumn 2 -EndColumn 8
$applianceinfo = Import-Excel $excelfile  -WorksheetName vCenter -StartRow 4 -EndRow 5 -StartColumn 1 -EndColumn 3
$networkinfo = Import-Excel $excelfile  -WorksheetName vCenter -StartRow 7 -EndRow 8 -StartColumn 1 -EndColumn 7
$os = Import-Excel $excelfile  -WorksheetName vCenter -StartRow 10 -EndRow 11 -StartColumn 1 -EndColumn 3 
$sso_ciep = Import-Excel $excelfile  -WorksheetName vCenter -StartRow 13 -EndRow 14 -StartColumn 1 -EndColumn 3

#Ensure the password specified has the appropriate complexity based on vCenter's requirements
$input = ($os."vCenter Root Password")
if (($input -cmatch '[a-z]') `
        -and ($input -match '\d') `
        -and ($input.length -ge 8) `
        -and ($input -match '!|@|#|%|^|&|$')) {
    Write-Output "Password complexity is sufficient. Continuing."
}
else {
    Write-Output "$input does not meet complexity requirements. Password must be at least 8 characters, include one numeric, and one special character."
    exit
}

$deploymentTarget = $targettype.'vCenter or ESXi'

#endregion import excel file into sections and validate input

#region Detect the OS (Windows, Linux, OSX)
if ($IsWindows -or $ENV:OS) {
    $installer_dir = ($VCSA_CLI_Installer_Path + "win32/")
    $installer = ($installer_dir + "vcsa-deploy.exe")
} 
elseif ($IsLinux) {
    $installer_dir = ($VCSA_CLI_Installer_Path + "lin64/")
    $installer = ($installer_dir + "vcsa-deploy")
    chmod -R +x $workspace
}
elseif ($IsMacOS) {
    $installer_dir = ($VCSA_CLI_Installer_Path + "mac/")
    $installer = ($installer_dir + "vcsa-deploy")
}
#endregion Detect the OS (Windows, Linux, OSX)

#region Create and format the JSON

#Detect whether we are deploying to vCenter or ESXi
switch ($deploymentTarget) {
    'vCenter' {
        Write-Output "Deploying to vCenter"
        $target = [ordered] @{
            vc = [ordered]@{
                __comments         = @("'datacenter' must end with a datacenter name, and only with a datacenter name. ",
                    "'target' must end with an ESXi hostname, a cluster name, or a resource pool name. ",
                    "The item 'Resources' must precede the resource pool name. ",
                    "All names are case-sensitive. ",
                    "For details and examples, refer to template help, i.e. vcsa-deploy {install|upgrade|migrate} --template-help")
                hostname           = $targetinfo."Target Host or vCenter"
                username           = $targetinfo."Username"
                password           = $targetinfo."Password"
                deployment_network = $targetinfo."PortGroup"

                <#
                datacenter         = @("Folder 1 (parent of Folder 2)",
                                        "Folder 2 (parent of Your Datacenter)",
                                        "Your Datacenter")
                #>
                datacenter         = $targetinfo."Datacenter (vCenter Only)"
                datastore          = $targetinfo."Datastore"
                <#
                target             = @( "Folder A (parent of Folder B)",
                                        "Folder B (parent of Your ESXi Host, or Cluster)",
                                        "Your ESXi Host, or Cluster")
                #>
                target             = $targetinfo."Cluster Name (vCenter Only)"
            }
        }
    }
    'ESXi' {
        Write-Output "Deploying to ESXi"
        $target = [ordered] @{
            esxi = [ordered]@{
                hostname           = $targetinfo."Target Host or vCenter"
                username           = $targetinfo."Username"
                password           = $targetinfo."Password"
                deployment_network = $targetinfo."PortGroup"
                datastore          = $targetinfo."Datastore"
            }
        }
    }
    Default {
        Write-Error "Invalid Deployment Target Specified. Exiting."
        exit
    }
}

<#
I'm aware that others have imported the json file provided by the installer...
I don't have a great reason that I didn't do that.. maybe I'm just different :-)
Either way - we are simply generating a hashtable here, and then writing it to a file.
#>
$common_properties = @{
    appliance = [ordered]@{
        __comments        = @("You must provide the 'deployment_option' key with a value, which will affect the VCSA's configuration parameters, such as the VCSA's number of vCPUs, the memory size, the storage size, and the maximum numbers of ESXi hosts and VMs which can be managed. For a list of acceptable values, run the supported deployment sizes help, i.e. vcsa-deploy --supported-deployment-sizes")
        thin_disk_mode    = $applianceinfo."Thin Disk?"
        deployment_option = $applianceinfo."vCenter Size"
        name              = $applianceinfo."VM Name"
    }
    network   = [ordered]@{
        ip_family   = $networkinfo."IP v4 or v6"
        mode        = $networkinfo."IP Allocation Mode"
        ip          = $networkinfo."IP Address"
        dns_servers = @($networkinfo.'DNS Server List').split(",")
        prefix      = ($networkinfo."CIDR Block").tostring()
        gateway     = $networkinfo."Default Gateway"
        system_name = $networkinfo."vCenter Hostname"
    }
    os        = [ordered]@{
        password    = $os."vCenter Root Password"
        ntp_servers = $os."NTP Servers"
        ssh_enable  = $os."Enable SSH By Default?"
    }
    sso       = [ordered]@{
        password    = $sso_ciep."SSO Password"
        domain_name = $sso_ciep."SSO Domain Name"
    }
}

$combined = [ordered]@{
    __version  = "2.13.0"
    __comments = "Sample template to deploy a vCenter Server Appliance with an embedded Platform Services Controller on an ESXi host."
    new_vcsa   = $target + $common_properties
    ceip       = [ordered]@{
        description = @{
            __comments = @("++++VMware Customer Experience Improvement Program (CEIP)++++",
                "VMware's Customer Experience Improvement Program (CEIP) ",
                "provides VMware with information that enables VMware to ",
                "improve its products and services, to fix problems, ",
                "and to advise you on how best to deploy and use our ",
                "products. As part of CEIP, VMware collects technical ",
                "information about your organization's use of VMware ",
                "products and services on a regular basis in association ",
                "with your organization's VMware license key(s). This ",
                "information does not personally identify any individual. ",
                "",
                "Additional information regarding the data collected ",
                "through CEIP and the purposes for which it is used by ",
                "VMware is set forth in the Trust & Assurance Center at ",
                "http://www.vmware.com/trustvmware/ceip.html . If you ",
                "prefer not to participate in VMware's CEIP for this ",
                "product, you should disable CEIP by setting ",
                "'ceip_enabled': false. You may join or leave VMware's ",
                "CEIP for this product at any time. Please confirm your ",
                "acknowledgement by passing in the parameter ",
                "--acknowledge-ceip in the command line.",
                "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++")       
        }
        
        settings    = @{ 
            #TODO I believe an extra member is needed if this is enabled
            ceip_enabled = $sso_ciep."Enable CIEP?"
        }
    }
}

$json = $combined | ConvertTo-Json -Depth 99
$fixtrue = $json.replace("`"true`"", "true")
$FinalJSON = $fixtrue.replace("`"false`"", "false")
#endregion Create and format the JSON

#region Write the json file to disk
switch ($deploymentTarget) {
    'vCenter' {  
        $FinalConfigFile = $workspace + "$(($FinalJSON | convertfrom-json).new_vcsa.vc.hostname).json"
    }
    'ESXi' {  
        $FinalConfigFile = $workspace + "$(($FinalJSON | convertfrom-json).new_vcsa.esxi.hostname).json"
    }
    Default { }
}
$FinalJSON | out-file -FilePath $FinalConfigFile
Write-Output ("JSON file written to: " + $FinalConfigFile)
#endregion Write the json file to disk

#region Start the install
Write-Output "Beginning install now.. this will take a few minutes. Please wait."
$arguments = "install --accept-eula --no-ssl-certificate-verification --log-dir $($VCSA_CLI_Installer_Path) $($FinalConfigFile)"

$pinfo = New-Object System.Diagnostics.ProcessStartInfo
$pinfo.FileName = $installer
$pinfo.RedirectStandardError = $true
$pinfo.RedirectStandardOutput = $true
$pinfo.UseShellExecute = $false
$pinfo.Arguments = $arguments
$p = New-Object System.Diagnostics.Process
$p.StartInfo = $pinfo
$p.Start() | Out-Null
$p.WaitForExit()
$stdout = $p.StandardOutput.ReadToEnd()
$stderr = $p.StandardError.ReadToEnd()

$stdout | out-file -Path ($VCSA_CLI_Installer_Path + "stdout.txt")
$stderr | out-file -Path ($VCSA_CLI_Installer_Path + "stderr.txt")
#endregion Start the install

if ($p.ExitCode -ne 0) {
    Write-Output "There was an error..."
    Write-Output "Process finished with exit code $($p.ExitCode)"
    Write-Output "Log data written to: $($VCSA_CLI_Installer_Path)stdout.txt and $($VCSA_CLI_Installer_Path)stderr.txt"
    $stderr
}
else {
    Write-Output "Install completed successfully."
}