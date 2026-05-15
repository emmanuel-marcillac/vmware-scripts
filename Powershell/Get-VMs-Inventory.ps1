###########################################################################
###
### Get VM Inventory from multiple vCenters and export result in .csv format
### Export file is done under $en v:USERPROFILE\documents\Reports
### You can change variable $outputPath and $OutputFile to meet your needs. 
###
###########################################################################

<#
.SYNOPSIS
    Export VM inventory From multiple vCenter
.DESCRIPTION
    This script is used to export to csv file VM inventory from multiple vCenters
.OUTPUTS
    Export csv file
.NOTES
    Author        Emmanuel MARCILLAC
#>

# Variable declaration
$Report = New-Object System.Collections.ArrayList
$DateTime = $((Get-Date).ToString('yyyy-MM-dd_hh-mm-ss'))
 
# Set report output path
$OutputPath = "$env:USERPROFILE\Documents\"
If ( -Not (Test-Path -Path $OutputPath)) {
    New-Item -ItemType directory -Path $OutputPath
}

# Set report output file name
$Outputfile = "Inventory-VMs-$DateTime"

# Get User to connect to vCenter Server
$vCenterUser = Read-Host "Enter your user name (DOMAIN\User or user@domain.com)"

# Get Password to connect to the vCenter Server
$vCenterUserPassword = Read-Host "Enter your password (no worries it is a secure string)" -AsSecureString:$true

# Collect username and password as credentials
$Credentials = New-Object System.Management.Automation.PSCredential -ArgumentList $vCenterUser,$vCenterUserPassword

$vCenterList = @("lbn-vcenter-01.ad.lbn.fr",
			"lbn-vcenter-02.ad.lbn.fr",
			"lbn-vcenter-05.ad.lbn.fr",
			"aka-vcenter-01.ad.lbn.fr")

ForEach ($vCenter in $vCenterList)
{
	Connect-VIServer -Server $vCenter -Credential $Credentials -ErrorAction Ignore | Out-Null
	
	If($? -Eq $True)
	{
	Write-Host "Connected to your vCenter server $vCenter" -ForegroundColor Green

	Write-Host "Processing Virtual Machine Inventory on vCenter $Vcenter..." -ForegroundColor Green
	
	$VMs = Get-vm | ? {$_.Name -notmatch "vCLS"}

	Foreach ($VM in $VMs){
	
	$Object = [PSCustomObject]@{
		vCenter			= $VM.Uid.Split('@')[1].Split('.ad.lbn.fr')[0]
		Cluster			= $VM.VMHost.Parent.Name
		VirtualMachine	= $VM.name
		PowerState		= $VM.PowerState
		NumCpu			= $VM.NumCpu
		MemGB			= $VM.MemoryGB
		DiskSizeGB		= $VM | Get-HardDisk | measure-object -property CapacityGB -sum | select-object -expand sum
		LBNREF 			= $VM.CustomFields.Item('LBNREF')
		VIRTUALTAG		= $VM.CustomFields.Item('VIRTUALTAG')
		}
	$Report.add($Object) | Out-Null
	}
	Write-Host "Exporting to csv file..." -ForegroundColor blue
	Write-Host "Export file named "$Outputfile".csv is available at "$OutputPath" location" -ForegroundColor blue

	$Report | Sort-Object -Property vCenter,Cluster,Name| Export-Csv  ("$OutputPath"+"$Outputfile.csv") -NoTypeInformation -UseCulture

	Disconnect-VIServer -server $vCenter -Confirm:$false
	Write-Host "Disconnected from your vCenter Server $vCenter - have a great day :)" -ForegroundColor Green

	}
	else {
	Write-Host "Cannot complete login on $vCenter due to an incorrect user name or password" -ForegroundColor Red
	}

}

