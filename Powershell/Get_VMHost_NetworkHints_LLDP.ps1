#############################################################
###
### Get VMHost Network Hints Using LLDP
###
##############################################################

# Get the vCenter Server Name to connect to
$vCenterServer = Read-Host "Enter vCenter Server host name (DNS with FQDN or IP address)"

# Get User to connect to vCenter Server
$vCenterUser = Read-Host "Enter your user name (DOMAIN\User or user@domain.com)"

# Get Password to connect to the vCenter Server
$vCenterUserPassword = Read-Host "Enter your password (no worries it is a secure string)" -AsSecureString:$true

# Collect username and password as credentials
$Credentials = New-Object System.Management.Automation.PSCredential -ArgumentList $vCenterUser,$vCenterUserPassword

# Connect to the vCenter Server with collected credentials
Connect-VIServer -Server $vCenterServer -Credential $Credentials -ErrorAction Ignore | Out-Null 

If($? -Eq $True)
{
	Write-Host "Connected to your vCenter server $vCenterServer" -ForegroundColor Green

$LLDPResultArray = @()

	Get-VMHost | Where-Object {$_.ConnectionState -eq "Connected"} |
    %{Get-View $_.ID} |
    %{$esxname = $_.Name; Get-View $_.ConfigManager.NetworkSystem} |
        %{ foreach($physnic in $_.NetworkInfo.Pnic){
            $pnicInfo = $_.QueryNetworkHint($physnic.Device)
                foreach($hint in $pnicInfo)
                {
                 ## if the switch support LLDP, and you have LLDP enabled on the ESXi host physical NIC, you will get LLDP information. LLDP information collected can differ based on the switch vendor.
                 ## so adjust the fields you want to collect based on your environment and switch vendor.
                 if ($hint.LldpInfo)
                    {
                     $LLDPResult = "" | select-object VMHost, PhysicalNic, PhysSW_PortName, PhysSW_PortId, PhysSW_Name, PhysSW_Description, PhysSW_MGMTIP, PhysSW_MTU
		             $LLDPResult.VMHost = $esxname
		             $LLDPResult.PhysicalNic = $physnic.Device
		             $LLDPResult.PhysSW_PortName = ($hint.LLDPInfo.Parameter | ? { $_.Key -eq "Port Description" }).Value
		             $LLDPResult.PhysSW_PortId = ($hint.LLDPInfo.portId)
		             $LLDPResult.PhysSW_Name = ($hint.LLDPInfo.Parameter | ? { $_.Key -eq "System Name" }).Value
		             $LLDPResult.PhysSW_Description = ($hint.LLDPInfo.Parameter | ? { $_.Key -eq "System Description" }).Value
		             $LLDPResult.PhysSW_MGMTIP = ($hint.LLDPInfo.Parameter | ? { $_.Key -eq "Management Address" }).Value
		             $LLDPResult.PhysSW_MTU = ($hint.LLDPInfo.Parameter | ? { $_.Key -eq "MTU" }).Value
		             $LLDPResultArray += $LLDPResult
                    }
                 if(!($hint.LldpInfo))
                    {
                     Write-Host "$esxname $($physnic.Device) - No LLDP information available." 
                    }
                }
            }
    }

if ($LLDPResultArray)
{
    Write-Host "LLDP Information Retrieved:" -ForegroundColor Green
    $LLDPResultArray | Format-Table -AutoSize
}	
# Disconnecting from the vCenter Server
	Disconnect-VIServer -Confirm:$false
	Write-Host "Disconnected from your vCenter Server $vCenterServer - have a great day :)" -ForegroundColor Green
}
else {
	Write-Host "Cannot complete login on $vCenterServer due to an incorrect user name or password" -ForegroundColor Red
}