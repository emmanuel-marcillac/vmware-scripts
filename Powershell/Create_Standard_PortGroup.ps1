#############################################################
###
### Create Standard PortGroup On ESXi inside a Cluster
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

# Provide Cluster Name
$ClusterName = Read-Host "Enter VMware Cluster Name where PortGroup will be create on each ESXi member of this cluster"

# Provide Cluster Name
$vSwitchName = Read-Host "Enter Standard vSwitch Name"

# Provide Cluster Name
$PortGroupName = Read-Host "Enter PortGroup Name"

# Provide VLAN id
$VLANid = Read-Host "Enter VLAN id"

Write-Host "Processing Strandard Portgroup named $PortGroupName (vlan id $VLANid) creation, inside vswitch named $vSwitchName on ESXis members of cluster named $ClusterName" -ForegroundColor Green

#Call New-virtualPortGroup on each ESXi Cluster Members
Get-Cluster -Name $ClusterName | Get-VMHost | ForEach-Object { New-VirtualPortGroup -VirtualSwitch ( Get-VirtualSwitch -Name $vSwitchName -VMHost $_ ) -Name $PortGroupName -VLanId $VLANid }

# Disconnecting from the vCenter Server
Disconnect-VIServer -Confirm:$false
Write-Host "Disconnected from your vCenter Server $vCenterServer - have a great day :)" -ForegroundColor Green
}
else {
	Write-Host "Cannot complete login on $vCenterServer due to an incorrect user name or password" -ForegroundColor Red
}