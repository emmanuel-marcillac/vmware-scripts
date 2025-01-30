<#
.SYNOPSIS
    Create_vCenterRole_Zerto.ps1 - PowerShell Script to create a new vCenter Role with all the required permission for Zerto
.DESCRIPTION
    This script is used to create a new role on your vCenter server.
    The newly created role will be filled with the needed permissions for using it with Veeam Backup & Replication
.OUTPUTS
    Results are printed to the console.
.NOTES
    Author        Falko Banaszak, https://virtualhome.blog, Twitter: @Falko_Banaszak
#>

# Here are all necessary and cumualative vCenter Privileges needed for all operations of Zerto
$ZertoPrivileges = @(
	'Alarm.Create',
    'Alarm.Delete',
	'Authorization.ModifyPermissions',
    'Datastore.AllocateSpace',
	'Datastore.Config',
	'Datastore.Browse',
    'Datastore.DeleteFile',
    'Datastore.FileManagement',
	'Datastore.UpdateVirtualMachineFiles',
	'StoragePod.Config',
	'Extension.Register',
	'Extension.Unregister',
	'Folder.Create',
	'Global.LogEvent',
    'Global.CancelTask',
    'Global.Diagnostics',
	'Global.DisableMethods',
	'Global.EnableMethods',
	'Host.Inventory.EditCluster',
	'Host.Config.AutoStart',
	'Host.Config.NetService',
	'Host.Config.AdvancedConfig',
	'Host.Config.Settings',
	'Host.Config.Patch',
	'Network.Assign',
	'Resource.AssignVMToPool',
	'Resource.AssignVAppToPool',
	'Resource.HotMigrate',
	'Resource.ColdMigrate',
	'Sessions.ValidateSession',
	'Task.Create',
	'Task.Update',
	'VApp.ApplicationConfig',
	'VApp.Import',
	'VApp.AssignVM',
	'VApp.AssignResourcePool',
	'VApp.Create',
	'VApp.Delete',
	'VApp.PowerOn',
	'VApp.PowerOff',
	'VirtualMachine.Config.AddExistingDisk',
	'VirtualMachine.Config.AddNewDisk',
	'VirtualMachine.Config.RemoveDisk',
	'VirtualMachine.Config.RawDevice',
	'VirtualMachine.Config.CPUCount',
	'VirtualMachine.Config.Memory',
	'VirtualMachine.Config.AddRemoveDevice',
	'VirtualMachine.Config.EditDevice',
	'VirtualMachine.Config.Settings',
	'VirtualMachine.Config.Resource',
	'VirtualMachine.Config.UpgradeVirtualHardware',
	'VirtualMachine.Config.AdvancedConfig',
	'VirtualMachine.Config.SwapPlacement',
	'VirtualMachine.Config.DiskExtend',
	'VirtualMachine.Config.ManagedBy',
	'VirtualMachine.Inventory.Create',
	'VirtualMachine.Inventory.CreateFromExisting',
	'VirtualMachine.Inventory.Register',
	'VirtualMachine.Inventory.Delete',
	'VirtualMachine.Inventory.Unregister',
	'VirtualMachine.Interact.PowerOn',
	'VirtualMachine.Interact.PowerOff')	

# Get the vCenter Server Name to connect to
$vCenterServer = Read-Host "Enter vCenter Server host name (DNS with FQDN or IP address)"

# Get User to connect to vCenter Server
$vCenterUser = Read-Host "Enter your user name (DOMAIN\User or user@domain.com)"

# Get Password to connect to the vCenter Server
$vCenterUserPassword = Read-Host "Enter your password (no worries it is a secure string)" -AsSecureString:$true

# Collect username and password as credentials
$Credentials = New-Object System.Management.Automation.PSCredential -ArgumentList $vCenterUser,$vCenterUserPassword

# Connect to the vCenter Server with collected credentials
Connect-VIServer -Server $vCenterServer -Credential $Credentials | Out-Null
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