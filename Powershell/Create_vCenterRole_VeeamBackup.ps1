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

# Here are all necessary and cumulative vCenter Privileges needed for all operations of VeeamBackup
$VeeamBackupPrivileges = @(
	'Global.ManageCustomFields',
	'Global.SetCustomField',
	'Global.LogEvent',
	'Global.Licenses',
	'Global.Settings',
	'Global.DisableMethods',
	'Global.EnableMethods',
	'Cryptographer.Access',
	'Datastore.Browse',
	'Datastore.DeleteFile',
	'Datastore.FileManagement',
	'Datastore.AllocateSpace',
	'Datastore.Config',
	'Network.Assign',
	'Resource.AssignVMToPool',
	'StoragePod.Config',
	'StorageProfile.Update',
	'StorageProfile.View',
	'VApp.AssignVM',
	'VApp.AssignResourcePool',
	'VApp.Unregister',
	'VirtualMachine.Config.DiskLease',
	'VirtualMachine.Config.AddNewDisk',
	'VirtualMachine.Config.AdvancedConfig',
	'VirtualMachine.Config.Settings',
	'VirtualMachine.Config.DiskExtend',
	'VirtualMachine.Config.EditDevice',
	'VirtualMachine.Config.ChangeTracking',
	'VirtualMachine.Inventory.Register',
	'VirtualMachine.Inventory.Unregister',
	'VirtualMachine.GuestOperations.Query',
	'VirtualMachine.GuestOperations.Modify',
	'VirtualMachine.GuestOperations.Execute',
	'VirtualMachine.Interact.DeviceConnection',
	'VirtualMachine.Interact.GuestControl',
	'VirtualMachine.Provisioning.DiskRandomAccess',
	'VirtualMachine.Provisioning.DiskRandomRead',
	'VirtualMachine.Provisioning.GetVmFiles',
	'VirtualMachine.State.CreateSnapshot',
	'VirtualMachine.State.RevertToSnapshot',
	'VirtualMachine.State.RemoveSnapshot',
	'VirtualMachine.State.RenameSnapshot')

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
New-VIRole -Name $NewRole -Privilege (Get-VIPrivilege -Id $VeeamBackupPrivileges) | Out-Null
Write-Host "Your new vCenter role has been created, here it is:" -ForegroundColor Green
Get-VIRole -Name $NewRole | Select-Object Description, PrivilegeList, Server, Name | Format-List

# Disconnecting from the vCenter Server
Disconnect-VIServer -Confirm:$false
Write-Host "Disconnected from your vCenter Server $vCenterServer - have a great day :)" -ForegroundColor Green
}
else {
	Write-Host "Cannot complete login on $vCenterServer due to an incorrect user name or password" -ForegroundColor Red
}