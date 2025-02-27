<#
.SYNOPSIS
    Create_vCenterRole_Packer.ps1 - PowerShell Script to create a new vCenter Role with all the required permission for Packer
.DESCRIPTION
    This script is used to create a new role on your vCenter server.
    The newly created role will be filled with the needed permissions for using it with Packer
.OUTPUTS
    Results are printed to the console.
.NOTES
    Author        Falko Banaszak, https://virtualhome.blog, Twitter: @Falko_Banaszak
#>

# Here are all necessary and cumualative vCenter Privileges needed for all operations of Paker
$ZertoPrivileges = @(
	'Datastore.Browse',
	'Datastore.FileManagement',
	'Datastore.AllocateSpace',
	'Network.Assign',
	'VirtualMachine.Inventory.Create',
	'VirtualMachine.Inventory.CreateFromExisting',
	'VirtualMachine.Inventory.Register',
	'VirtualMachine.Inventory.Delete',
	'VirtualMachine.Inventory.Unregister',
	'VirtualMachine.Inventory.Move',
	'VirtualMachine.Interact.PowerOn',
	'VirtualMachine.Interact.PowerOff',
	'VirtualMachine.Interact.Suspend',
	'VirtualMachine.Interact.Reset',
	'VirtualMachine.Interact.Pause',
	'VirtualMachine.Interact.AnswerQuestion',
	'VirtualMachine.Interact.ConsoleInteract',
	'VirtualMachine.Interact.DeviceConnection',
	'VirtualMachine.Interact.SetCDMedia',
	'VirtualMachine.Interact.SetFloppyMedia',
	'VirtualMachine.Interact.ToolsInstall',
	'VirtualMachine.Interact.GuestControl',
	'VirtualMachine.Interact.DefragmentAllDisks',
	'VirtualMachine.Interact.CreateSecondary',
	'VirtualMachine.Interact.TurnOffFaultTolerance',
	'VirtualMachine.Interact.MakePrimary',
	'VirtualMachine.Interact.TerminateFaultTolerantVM',
	'VirtualMachine.Interact.DisableSecondary',
	'VirtualMachine.Interact.EnableSecondary',
	'VirtualMachine.Interact.Record',
	'VirtualMachine.Interact.Replay',
	'VirtualMachine.Interact.Backup',
	'VirtualMachine.Interact.CreateScreenshot',
	'VirtualMachine.Interact.PutUsbScanCodes',
	'VirtualMachine.Interact.SESparseMaintenance',
	'VirtualMachine.Interact.DnD',
	'VirtualMachine.Config.Rename',
	'VirtualMachine.Config.Annotation',
	'VirtualMachine.Config.AddExistingDisk',
	'VirtualMachine.Config.AddNewDisk',
	'VirtualMachine.Config.RemoveDisk',
	'VirtualMachine.Config.RawDevice',
	'VirtualMachine.Config.HostUSBDevice',
	'VirtualMachine.Config.CPUCount',
	'VirtualMachine.Config.Memory',
	'VirtualMachine.Config.AddRemoveDevice',
	'VirtualMachine.Config.EditDevice',
	'VirtualMachine.Config.Settings',
	'VirtualMachine.Config.Resource',
	'VirtualMachine.Config.UpgradeVirtualHardware',
	'VirtualMachine.Config.ResetGuestInfo',
	'VirtualMachine.Config.ToggleForkParent',
	'VirtualMachine.Config.AdvancedConfig',
	'VirtualMachine.Config.DiskLease',
	'VirtualMachine.Config.SwapPlacement',
	'VirtualMachine.Config.DiskExtend',
	'VirtualMachine.Config.ChangeTracking',
	'VirtualMachine.Config.QueryUnownedFiles',
	'VirtualMachine.Config.ReloadFromPath',
	'VirtualMachine.Config.QueryFTCompatibility',
	'VirtualMachine.Config.MksControl',
	'VirtualMachine.Config.ManagedBy',
	'VirtualMachine.State.CreateSnapshot',
	'VirtualMachine.State.RevertToSnapshot',
	'VirtualMachine.State.RemoveSnapshot',
	'VirtualMachine.State.RenameSnapshot',
	'VirtualMachine.Provisioning.Customize',
	'VirtualMachine.Provisioning.Clone',
	'VirtualMachine.Provisioning.PromoteDisks',
	'VirtualMachine.Provisioning.CreateTemplateFromVM',
	'VirtualMachine.Provisioning.DeployTemplate',
	'VirtualMachine.Provisioning.CloneTemplate',
	'VirtualMachine.Provisioning.MarkAsTemplate',
	'VirtualMachine.Provisioning.MarkAsVM',
	'VirtualMachine.Provisioning.ReadCustSpecs',
	'VirtualMachine.Provisioning.ModifyCustSpecs',
	'VirtualMachine.Provisioning.DiskRandomAccess',
	'VirtualMachine.Provisioning.DiskRandomRead',
	'VirtualMachine.Provisioning.FileRandomAccess',
	'VirtualMachine.Provisioning.GetVmFiles',
	'VirtualMachine.Provisioning.PutVmFiles',
	'Resource.AssignVMToPool',
	'VirtualMachine.Config.Unlock')

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

	# Provide a name for your new role
	$NewRole = Read-Host "Enter your desired name for the new vCenter role"
	Write-Host "Thanks, your new vCenter role will be named $NewRole" -ForegroundColor Green

	# Creating the new role with the needed permissions
	New-VIRole -Name $NewRole -Privilege (Get-VIPrivilege -Id $ZertoPrivileges) | Out-Null
	Write-Host "Your new vCenter role has been created, here it is:" -ForegroundColor Green
		Get-VIRole -Name $NewRole | Select-Object Description, PrivilegeList, Server, Name | Format-List

	# Disconnecting from the vCenter Server
	Disconnect-VIServer -Confirm:$false
	Write-Host "Disconnected from your vCenter Server $vCenterServer - have a great day :)" -ForegroundColor Green
}
else {
	Write-Host "Cannot complete login on $vCenterServer due to an incorrect user name or password" -ForegroundColor Red
}