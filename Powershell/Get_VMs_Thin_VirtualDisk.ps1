#############################################################
###
### Get all thin provisioned virtual disks
###
##############################################################
$vmdiskformat = @()

get-view -ViewType VirtualMachine -Property Name, "Config.Hardware.Device" | %{
	$vmName = $_.name
	$_.Config.Hardware.Device | where {$_.GetType().Name -eq "VirtualDisk"} | %{
		if($_.Backing.ThinProvisioned){
			$sizeInGb = [Math]::Round(($_.CapacityInKB / 1MB),2)
			$type = if (!$_.Backing.ThinProvisioned) { �THICK� } else { "THIN" }
			$label = $_.DeviceInfo.Label
			$vmdiskformat += "" | Select-Object @{n="VmName";e={$vmName}},@{n="DiskLabel";e={$label}},@{n="Backing";e={$type}},@{n="SizeInGB";e={$sizeInGb}}
		}
	}
}
#Print out our table
$vmdiskformat | format-table -autosize