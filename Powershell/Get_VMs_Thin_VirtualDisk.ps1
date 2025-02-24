#############################################################
###
### Get all thin provisioned virtual disks
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

$vmdiskformat = @()

get-view -ViewType VirtualMachine -Property Name, "Config.Hardware.Device" | %{
	$vmName = $_.name
	$_.Config.Hardware.Device | where {$_.GetType().Name -eq "VirtualDisk"} | %{
		if($_.Backing.ThinProvisioned){
			$sizeInGb = [Math]::Round(($_.CapacityInKB / 1MB),2)
			$type = if (!$_.Backing.ThinProvisioned) { "THICK" } else { "THIN" }
			$label = $_.DeviceInfo.Label
			$vmdiskformat += "" | Select-Object @{n="VmName";e={$vmName}},@{n="DiskLabel";e={$label}},@{n="Backing";e={$type}},@{n="SizeInGB";e={$sizeInGb}}
		}
	}
}
#Print out our table
$vmdiskformat | format-table -autosize

# Disconnecting from the vCenter Server
Disconnect-VIServer -Confirm:$false
Write-Host "Disconnected from your vCenter Server $vCenterServer - have a great day :)" -ForegroundColor Green

}
else {
	Write-Host "Cannot complete login on $vCenterServer due to an incorrect user name or password" -ForegroundColor Red
}