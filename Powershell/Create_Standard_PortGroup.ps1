#############################################################
###
### Create Standard PortGroup On ESXi inside a Cluster
###
##############################################################

# Prompt the user to enter the vCenter Server host name (DNS with FQDN or IP address)
$vCenterServer = Read-Host "Enter vCenter Server host name (DNS with FQDN or IP address)"

# Prompt the user to enter their username for connecting to the vCenter Server (DOMAIN\User or user@domain.com)
$vCenterUser = Read-Host "Enter your user name (DOMAIN\User or user@domain.com)"

# Prompt the user to enter their password securely as a secure string
$vCenterUserPassword = Read-Host "Enter your password (no worries it is a secure string)" -AsSecureString:$true

# Create a PSCredential object using the provided username and secure password
$Credentials = New-Object System.Management.Automation.PSCredential -ArgumentList $vCenterUser,$vCenterUserPassword

# Connect to the specified vCenter Server using the credentials, ignoring errors and suppressing output
Connect-VIServer -Server $vCenterServer -Credential $Credentials -ErrorAction Ignore | Out-Null 

# Check if the last command (Connect-VIServer) was successful
If($? -Eq $True)
{
	# Display a success message indicating connection to the vCenter server
	Write-Host "Connected to your vCenter server $vCenterServer" -ForegroundColor Green

	# Prompt the user to enter the VMware Cluster Name where the PortGroup will be created on each ESXi member
	$ClusterName = Read-Host "Enter VMware Cluster Name where PortGroup will be create on each ESXi member of this cluster"

	# Prompt the user to enter the Standard vSwitch Name
	$vSwitchName = Read-Host "Enter Standard vSwitch Name"

	# Prompt the user to enter the PortGroup Name
	$PortGroupName = Read-Host "Enter PortGroup Name"

	# Prompt the user to enter the VLAN ID
	$VLANid = Read-Host "Enter VLAN id"

	# Display a processing message with the details of the PortGroup creation
	Write-Host "Processing Strandard Portgroup named $PortGroupName (vlan id $VLANid) creation, inside vswitch named $vSwitchName on ESXis members of cluster named $ClusterName" -ForegroundColor Green

	# Retrieve the cluster by name, get all VMHosts in it, and for each host, create a new virtual port group on the specified vSwitch with the given name and VLAN ID
	Get-Cluster -Name $ClusterName | Get-VMHost | ForEach-Object { New-VirtualPortGroup -VirtualSwitch ( Get-VirtualSwitch -Name $vSwitchName -VMHost $_ ) -Name $PortGroupName -VLanId $VLANid }

	# Disconnect from the vCenter Server without confirmation
	Disconnect-VIServer -Confirm:$false
	# Display a disconnection message
	Write-Host "Disconnected from your vCenter Server $vCenterServer - have a great day :)" -ForegroundColor Green
}
else {
	# Display an error message if login failed due to incorrect credentials
	Write-Host "Cannot complete login on $vCenterServer due to an incorrect user name or password" -ForegroundColor Red
}