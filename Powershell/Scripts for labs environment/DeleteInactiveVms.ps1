#***********************************************************************************************************************************************#
#      Script Name   :   DeleteInactiveVms.ps1                                                                                                  #
#      Purpose		 :   Get the report of VMS Powered Off 60 Days ago or more and delete them				                                    #
#	   Pre requisite :   login and password are stored in a xml file to create it launch de following command                                   #
#                    :   New-VICredentialStoreItem -Host "vcenter_fqdn" -User "user_name" -Password "secret_password" -File "path_to_xml_file"  #
#                    :   Logging powershell module need to be installed                                                                         #
#                    :                                                                                                                          #
#      Author		 :                                                                                                                          #
#                                                                                                                                               #
#***********************************************************************************************************************************************#

# Import needfull module
import-module logging

# Configure Logging module options
Set-LoggingDefaultLevel -Level 'INFO'
Add-LoggingTarget -Name File -Configuration @{Path = '%PATHTOLOG%\logs\VMsDeleted_%{+%Y-%m-%d}.log'}

# Variables
$VCServer = "vCenter.domain.local"
$logincredential = Get-VICredentialStoreItem -Host lbnlabo-vcenter.ad.lbn.fr -File %PATHTOXMLFILE%\Credential.xml
$MaxDays = 60
$VMstodelete = @()
 
# Connection to vCenter
$connection = Connect-VIServer -Server $VCServer -user $logincredential.User -password $logincredential.Password -ErrorAction SilentlyContinue -WarningAction 0 | Out-Null

# If the connection is ok we go futher in the script
If($? -Eq $True)
{
	Write-log -Message "Login successfully to $VCServer"
	
	# List all virtual machine PoweredOff except vCenter
	$PoweredOffvms = Get-VM | where {$_.PowerState -eq "PoweredOff"} | Where { $_.Name -ne "%VMVCENTERNAME%"}
	$NumberPoweredOffVms = $PoweredOffvms.count
	write-log -Message "$NumberPoweredOffVms Powered Off Virtual Machines has been found"
		
	# If there is powered off vms we go futher in the script
	If ($PoweredOffvms)
	{
	 Write-log -Message "Starting process to research virtual machine in inactive state for more than $MaxDays days and candidate to be deleted..."
	 Write-log -Message "Parsing VCenter Events logs"	 
	 Write-log -Message "..."
	 
	 # For each virtual machine we retrieve last event that could explain why the virtual machine are inactive and candidate to be deleted.
	 Foreach ($vm in $PoweredOffvms)
		{
		$EventsLog = Get-VIEvent -Entity $vm -MaxSamples ([int]::MaxValue) | Sort-Object -Property CreatedTime -Descending | `
					Where-Object { $_.Gettype().Name -eq "VmPoweredOffEvent" `
							   -or $_.Gettype().Name -eq "VmCreatedEvent"    `
							   -or $_.Gettype().Name -eq "VmClonedEvent"     `
							   -or $_.Gettype().Name -eq "VmRegisteredEvent"} | Select-Object -First 1
			
			# For logging purpose we have to decompose $EventsLog in sub-ojbect
			$EventsLogs_CreatedTime =  $EventsLog.CreatedTime
			$EventsLogs_FullFormattedMessage = $EventsLog.FullFormattedMessage     
			
			# we count days between the event and today
			$timediff = ((get-date) - $EventsLog.CreatedTime).days
			
			# if the event is greater than $MaxDay the virtual Machine is candidate to be delete and pass in an array
			If ($timediff -ge $Maxdays)
			{
			$VMstodelete += $vm.name
			Write-log -Message "$vm is powered off. Logs retrieved : ***$EventsLogs_CreatedTime : $EventsLogs_FullFormattedMessage***"
			Write-log -Message "--> Exam of the vcenter event log show $vm is candidate for deletion"
			}
			
			# if not we do nothing
			Else
			{
			}
						
		}
	
	Write-log -Message "..."	
		
	# Log if there is no virtual machine powered off to delete
	if ($VMstodelete.count -eq 0)
	{
	Write-log -Message "After analysis none of the $NumberPoweredOffVms virtual machines is to be deleted"
	}
	Else
	{
	}
		
	 # loop to delete virtual machine witout any confirmation
	 Foreach ($i in $VMstodelete)
		{
		Remove-VM -VM $i -DeletePermanently -Confirm:$false
		Write-log -Message "Deleting virtual machine $i"
		}
	}
	Else
	{
	# There are no virtual machine powered off, we log this and disconnect from vCenter
	Write-log -Message "`nAll virtual machines are powered on !`n"
	}
	Disconnect-VIServer * -Confirm:$false -ErrorAction SilentlyContinue -WarningAction 0 | Out-Null
	Write-log -Message "`nDisconnecting from vCenter $VCServer`n"
}
	# If connection failed we log the error
Else
{
		Write-log -level 'ERROR' -Message "`nFailed to connect to $VCServer`n"
}