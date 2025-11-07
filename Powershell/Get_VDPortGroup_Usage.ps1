<#
.SYNOPSIS
    List Port Group usage - PowerShell Script to list all Port Groups and their usage on VMs and VMkernel Adapters
.DESCRIPTION
    This script list all port groups and their usage on VMs and VMkernel Adapters
    Can be used to find unused port groups
.OUTPUTS
    Results are printed to the console.
.NOTES
    Author        Emmanuel Marcillac
#>
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

$info = @()
foreach($dvPortgroup in (Get-VirtualPortgroup -Distributed | Sort-Object Name)){
    $dvPortgroupInfo = New-Object PSObject -Property @{            
        Name = $dvPortgroup.Name
        VlanId = $dvPortgroup.ExtensionData.Config.DefaultPortConfig.Vlan.VlanId
        NumPorts = $dvPortgroup.NumPorts
        NumVMs = $dvPortgroup.ExtensionData.vm.count
		NumVMKernel = ((get-vdport -vdportgroup $dvPortgroup.Name) | Where-Object {$_.ConnectedEntity -like "vmk*"}).count
    }  
    $info += $dvPortgroupInfo
}
$info | Select-Object Name,NumPorts,NumVMs,NumVMKernel | format-table

   

# Disconnecting from the vCenter Server
Disconnect-VIServer -Confirm:$false
Write-Host "Disconnected from your vCenter Server $vCenterServer - have a great day :)" -ForegroundColor Green

}
else {
	Write-Host "Cannot complete login on $vCenterServer due to an incorrect user name or password" -ForegroundColor Red
}