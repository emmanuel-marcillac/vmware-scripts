#############################################################
###
### Get VMhost various information
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
    $Report = @()
    $VMHostList =  Get-VMHost
	    Foreach ($VMHost in $VMHostList){
		    $row = "" | Select-Object Name, Manufacturer, Model, Version, Build, NumSocket, NumCore, MemoryGB, CpuUsage, MemoryUsage, VMPoweredOn
		    $row.Name = $VMHost.name
		    $row.Manufacturer = $VMHost.Manufacturer
		    $row.Model = $VMHost.Model
		    $row.Version = $VMHost.version
		    $row.Build = $VMHost.build
		    $row.NumSocket = $VMHost.extensiondata.hardware.CpuInfo.NumCpuPackages		
		    $row.NumCore = $VMHost.NumCPU
		    $row.MemoryGB = [math]::round($VMHost.MemoryTotalGB)
		    $row.CpuUsage = [math]::round($VMHost.CpuUSageMhz / $VMHost.CpuTotalMhz * 100 )
		    $row.MemoryUsage = [math]::round($VMHost.MemoryUsageGB / $VMHost.MemoryTotalGB * 100 )
		    $row.VMPoweredOn = (get-vmhost -name $VMHost | get-vm | Where-Object {$_.powerstate -match "PoweredOn"}).count
		    $Report += $row
	        }

$Report | format-table * -AutoSize
   

# Disconnecting from the vCenter Server
Disconnect-VIServer -Confirm:$false
Write-Host "Disconnected from your vCenter Server $vCenterServer - have a great day :)" -ForegroundColor Green

}
else {
	Write-Host "Cannot complete login on $vCenterServer due to an incorrect user name or password" -ForegroundColor Red
}