<#
.LINK http://www.virtjunkie.com/vsphere-test-cluster-connectivity/
.LINK https://github.com/jonhowe/Virtjunkie.com/blob/master/Test-ClusterNetworkConnectivity.ps1
#>
param(
	$vcenterserver = "vcenter67.pcm.net",
	$vswitch = "UCS-vDS001",
	$clustername = "UCS Cluster",
	$verbose = $false,
	$csvpath = "C:\powershell\PCMlab_test_csv.csv"
)

<#
***Fields in the CSV***
IP, GW, PG, netmask, vlan
#>

#1.) connect to the vcenter
$credential = get-credential
$conn = connect-viserver -server $vcenterserver -credential $credential | out-null

#2.) Get a list of all VMhosts attached to the specified Switch and cluster
$vmhosts = get-vdswitch -name $vswitch | get-vmhost | Where-Object { $_.parent.name -eq $clustername }

#3.) Import the CSV file that has the IP, Gateway, Port Group, NetMask, and vLAN
$ALL_VMK_CSV_Rows = import-csv -path $csvpath

#Create array that stores results
$RS = @()

#3a.) Loop through each VMhost one at a time
foreach ($vmhost in $vmhosts)
{
	#Loop through each VMkernel in the CSV one at a time
	foreach ($ONE_VMK_CSV_ROW in $ALL_VMK_CSV_Rows)
	{
		#Splatting for parameters for new-vmhostnetworkadapter
		$NewVMKParams = @{
			VMHost = $vmhost
			PortGroup = $ONE_VMK_CSV_ROW.pg
			VirtualSwitch = $vswitch
			IP = $ONE_VMK_CSV_ROW.ip
			SubnetMask = $ONE_VMK_CSV_ROW.netmask
		}
		#Optional logging - disabled by default
		Write-Verbose -vb:$true -Message ($NewVMKParams | Out-String)
		
		#create new object to contain results
		$PingResults = New-Object System.Object

		#Test to see if the vmkernel port is created successfully.. if so, continue to test connectivity
		if ($vmkernel = new-vmhostnetworkadapter @NewVMKParams -ErrorAction SilentlyContinue)
		{
			#Get the newly created VMKernel adapter
			$vmkobj = Get-VMHostNetworkAdapter -VMHost $vmhost -VirtualSwitch (Get-VDSwitch -Name $vswitch) -VMKernel | 
				Where-Object { $_.devicename -eq $vmkernel.devicename }
		
			#Use ESXCli to emulate this command: vmkping -I [newly created vmkernel IP] TO: [Gateway IP Specified in the CSV]
			$esxcli = Get-EsxCli -VMHost $vmhost -V2
			$params = $esxcli.network.diag.ping.CreateArgs()
			$params.host = $ONE_VMK_CSV_ROW.GW
			$params.interface = $vmkobj.devicename
			#the $res variable contains the results of the ping.. if you want, you can see all of the result info by printing $res.summary
			$res = $esxcli.network.diag.ping.Invoke($params)
			
			#optional logging - disabled by default
			write-verbose -vb:$verbose -Message ($res.summary | Out-String)
			$output = ("[$($vmhost.name)]: $($res.summary.Recieved / $res.summary.transmitted * 100)% success. Source: $($ONE_VMK_CSV_ROW.ip) Target: $($res.summary.hostaddr) || PG $($ONE_VMK_CSV_ROW.pg) (VLAN: $($ONE_VMK_CSV_ROW.vlan))")
			Write-Verbose -vb:$verbose -Message $output

			#Add properties to the object
			$PingResults | Add-Member -type NoteProperty -name Cluster -Value $clustername        
			$PingResults | Add-Member -type NoteProperty -name VMHost -Value $vmhost.name
			$PingResults | Add-Member -type NoteProperty -name SourceIP -Value $ONE_VMK_CSV_ROW.ip
			$PingResults | Add-Member -type NoteProperty -name TargetIP -Value $res.summary.hostaddr
			$PingResults | Add-Member -type NoteProperty -name PortGroup -Value $ONE_VMK_CSV_ROW.pg
			$PingResults | Add-Member -type NoteProperty -name VLAN -Value $ONE_VMK_CSV_ROW.vlan
			$PingResults | Add-Member -type NoteProperty -name PercentSuccess -Value ($res.summary.Recieved / $res.summary.transmitted * 100)
			$PingResults | Add-Member -type NoteProperty -name vSwitch -Value $vswitch
			
			#3d.) Remove vmkernel port
			remove-vmhostnetworkadapter -nic $vmkobj -confirm:$false
		}
		#if the vmkernel adapter is not created successfully, report the failure
		Else
		{
			#Optional Logging - disabled by default
			$output = ("[$($vmhost.name)]: ERROR || PG $($ONE_VMK_CSV_ROW.pg) (VLAN: $($ONE_VMK_CSV_ROW.vlan)) does not exist on $($vswitch)")
			write-verbose -verbose:$verbose $output

			#Add properties to the object
			$PingResults | Add-Member -type NoteProperty -name VMHost -Value $vmhost.name
			$PingResults | Add-Member -type NoteProperty -name PG -Value $ONE_VMK_CSV_ROW.pg
			$PingResults | Add-Member -type NoteProperty -name vLAN -Value $ONE_VMK_CSV_ROW.vlan
			$PingResults | Add-Member -type NoteProperty -name vSwitch -Value $vswitch
			$PingResults | Add-Member -type NoteProperty -name PercentSuccess -Value "ERROR"
		}

		#add object to array
		$RS += $PingResults
		break

	} # end foreach ($ONE_VMK_CSV_ROW in $ALL_VMK_CSV_Rows)
	break
} # end foreach ($vmhost in $vmhosts)

Write-Output $RS
#3e.) Disconnect from all vCenters
disconnect-viserver -server * -confirm:$false
 