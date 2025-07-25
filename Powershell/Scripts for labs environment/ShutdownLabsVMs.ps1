#***********************************************************************************************************************************************#
#      Script Name	 :   ShutdownLabsVMs.ps1                                                                                                    #
#      Purpose		 :   Shutdown All VMs Except vCenter and VMware appliances, Try shutdown Gracefully before Hard Shutdown them.              #
#	   Pre requisite :   login and password are stored in a xml file to create it launch de following command                                   #
#                    :   New-VICredentialStoreItem -Host "vcenter_fqdn" -User "user_name" -Password "secret_password" -File "path_to_xml_file"  #
#                    :   Logging powershell module need to be installed                                                                         #
#                    :                                                                                                                          #
#      Author		 :                                                                                                                          #
#                                                                                                                                               #
#***********************************************************************************************************************************************#
#
#
# Import needfull module
import-module logging

# Configure Logging module options
Set-LoggingDefaultLevel -Level 'INFO'
Add-LoggingTarget -Name File -Configuration @{Path = '%PATHTOLOGS%\ShutdownLabsVMs_%{+%Y-%m-%d}.log'}

# Variables
$VCServer = "vCenter.domain.local"
$logincredential = Get-VICredentialStoreItem -Host $VCServer -File %PATHTOXMLFILE%\Credential.xml
$vmsPoweringDown = new-object system.collections.arraylist

# Connection to vcenter
$connection = Connect-VIServer -Server $VCServer -user $logincredential.User -password $logincredential.Password -ErrorAction SilentlyContinue -WarningAction 0 | Out-Null

# If connection to vCenter is done we go futher in the script.
If($? -Eq $True)
{
 
 # We log successful login to vCenter
 Write-log -Message "Login successfully to $VCServer"
 
 Write-log -Message "Building virtual machine list to be powered off ..."
 Write-log -Message "..."
 
 # Get all VMs that are Powered On, except vCenter virtual machine
 $vms = Get-VM | where {$_.PowerState -eq "PoweredOn"} | Where { $_.Name -ne "%VCENTERNAME%" -and $_.Name -notlike "*nsx*" -and $_.Name -notlike "*vCLS*"}
 if ($vms)
 {
 	# Loop to Process each virtual machine
    foreach ($vm in $vms)
    {
     # If VMwaretools are installed and running, try a clean shutdown, if not turn off virtual machine
     $vmView = $vm | get-view
     $vmToolsStatus = $vmView.summary.guest.toolsRunningStatus
      if ($vmToolsStatus -eq "guestToolsRunning")
      {
       $result = Shutdown-VMGuest -VM $vm -confirm:$false
	   Write-log -Message  "VMwaretools are present and running, shutting down gracefully $vm" 
       $count = $vmsPoweringDown.add($vm)
	  }
      else
      {
       stop-vm -vm $vm -confirm:$false -ErrorAction SilentlyContinue -WarningAction 0 | Out-Null
	   Write-log -level WARNING -Message "VMwaretools are not present or not running, shutting down forcibly $vm" 
      }
    }
 
   # Wait until all VMs are powered down (or we reach a timeout)
   $waitmax = (get-date).addminutes(2)
   $startTime = (get-date)
   do
   {
    Write-log -Message "Waiting 2 Minute..."
      sleep 120
 
    Write-log -Message "Checking for still running machines..."
    for ($i = 0; $i -lt $vmsPoweringDown.count; $i++)
      {
         if ((Get-VM $vmsPoweringDown[$i]).PowerState -eq "PoweredOn")
		 {
		  $stillrunning = (Get-VM $vmsPoweringDown[$i]).name
		  Write-log -level WARNING -Message "$stillrunning is still powered on..."
          continue
         }
         else
         {
          $vmsPoweringDown.RemoveAt($i)
          $i--
         }
      }
   } while (($vmsPoweringDown.count -gt 0) -and (((get-date) -lt $waitmax)))
	
   # Shut down still running VMs
   if ($vmsPoweringDown.count -gt 0)
   {
      Write-log -Message  "Powering down still running machines..."
 
      foreach ($vmName in $vmsPoweringDown)
      {
         $vm = Get-VM $vmName
		 if ($vm.PowerState -eq "PoweredOn") {
            Stop-VM -vm $vm -confirm:$false -ErrorAction SilentlyContinue -WarningAction 0 | Out-Null
			Write-log -level WARNING -Message  "$vm cannot be gracefully shutdown, forcibly shutdown it now"
         }
      }
   }
   Write-log -Message "All Vms except vCenter has been powered off!" 
   Write-log -Message "..."
  } 
  Else
 {
	Write-log -level WARNING -Message "All Vms except vCenter and VMware appliances are already powered off !"
	Write-log -Message "..."
 }
	Disconnect-VIServer * -Confirm:$false -ErrorAction SilentlyContinue -WarningAction 0 | Out-Null
	Write-log -Message "Disconnecting from vCenter $VCServer"
}
#If connection to vCenter failed, log failure
Else
{
	Write-log -level WARNING -Message "Loggin to $VCServer failed"
}
 