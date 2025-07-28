#############################################################
###
### Get VMhost HBA WWN information
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

$hosti = Get-VMHost
    $reportwwn = foreach ($esxi in $hosti) {
        Get-VMHosthba -VMHost $esxi -type FibreChannel | where{$_.Status -eq 'online'} |
        Select  @{N="Host";E={$esxi.Name}},
            Name,
            # Retreive the WWN decimal information and format it as hexadecimal
            @{N='HBA WWN Node';E={$wwn = "{0:X}" -f $_.NodeWorldWideName; (0..7 | %{$wwn.Substring($_*2,2)}) -join ':'}},
            @{N='HBA WWN Port';E={$wwp = "{0:X}" -f $_.PortWorldWideName; (0..7 | %{$wwp.Substring($_*2,2)}) -join ':'}}
    }
    
$reportwwn | format-table -AutoSize
   

# Disconnecting from the vCenter Server
Disconnect-VIServer -Confirm:$false
Write-Host "Disconnected from your vCenter Server $vCenterServer - have a great day :)" -ForegroundColor Green

}
else {
	Write-Host "Cannot complete login on $vCenterServer due to an incorrect user name or password" -ForegroundColor Red
}