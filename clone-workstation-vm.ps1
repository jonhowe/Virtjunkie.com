<#
Original Links:
http://www.virtjunkie.com/clone-vm-in-workstation-15-pro-via-rest-api-using-powershell/
https://github.com/jonhowe/Virtjunkie.com/edit/master/clone-workstation-vm.ps1

The API will need to be running. Use this link to configure it.
https://docs.vmware.com/en/VMware-Workstation-Pro/15.0/com.vmware.ws.using.doc/GUID-C3361DF5-A4C1-432E-850C-8F60D83E5E2B.html
#>
$user = '[Username]'
$pass = '[Password]'
$VMToClone = "[Template Name To Clone]"
$newvmname = "[New VM Name]"
$REST_URL = "https://[Your IP and port]/api/vms"

function Select-VM {
    param (
        $vmname
    )

    $rs=Invoke-WorkstationRestRequest -method Get

    foreach ($vm in $rs)
    {
        $pathsplit = ($vm.path).split("/")
        $vmxfile = $pathsplit[($pathsplit.Length)-1]
        $thisVM = ($vmxfile).split(".")[0]
        if ($thisVM -eq $vmname) { return $vm;break}
    } 
}

function Select-OneVM {
    param (
        $vmid
    )
    $rs=Invoke-WorkstationRestRequest -method Get -uri ($REST_URL + "/$($vmid.id)")
    return $rs
}
function Set-Credentials {
    param (
        $username,
        $password
    )

    $pair = "${username}:${password}"
    $bytes = [System.Text.Encoding]::ASCII.GetBytes($pair)
    $base64 = [System.Convert]::ToBase64String($bytes)

    $basicAuthValue = "Basic $base64"
    return $basicAuthValue
}

function New-WorkstationVM {
    param (
        $sourcevmid,
        $newvmname
    )
    $body = @{
        'name' = $newvmname;
        'parentId' = $sourcevmid
    }
    $requestbody = ($body | ConvertTo-Json)
    $rs=Invoke-WorkstationRestRequest -method "POST" -body $requestbody
    return $rs
}

function Invoke-WorkstationRestRequest {
    param (
        $uri=$REST_URL,
        $method,
        $body=$null
    )

    $headers = @{
        'authorization' =  $basicAuthValue;
        'content-type' =  'application/vnd.vmware.vmw.rest-v1+json';
        'accept' = 'application/vnd.vmware.vmw.rest-v1+json';
        'cache-control' = 'no-cache'
    }
    $rs=Invoke-RestMethod -uri $uri -Headers $headers -SkipCertificateCheck -Method $method -Body $body
    return $rs
}

$creds = Set-Credentials -username $user -password $pass
$vmtoclone = Select-VM -vmname $VMToClone 
$result=New-WorkstationVM -sourcevmid $VMToClone.id -newvmname $newvmname
$newvm = select-onevm -vmid $result

return $newvm
