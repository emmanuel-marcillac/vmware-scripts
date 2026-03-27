<#
.SYNOPSIS
Export all vCenter VMs network adapters with PortGroup, MAC, IPv4

.DESCRIPTION
Enumerates all VMs (PowerCLI),
correlates each virtual NIC with guest-reported IP addresses via MAC,
and emits a CSV with robust null-safe handling.
#>

# Variable declaration
$DateTime = $((Get-Date).ToString('yyyy-MM-dd_hh-mm-ss'))
$allRows = New-Object System.Collections.Generic.List[object]

# Set report output path
$OutputPath = "$env:USERPROFILE\OneDrive - Accenture\Documents\Reports\"
If ( -Not (Test-Path -Path $OutputPath)) {
    New-Item -ItemType directory -Path $OutputPath
}

# Set report output file name
$Outputfile = "All-Agile-VMs-$DateTime"

# Function to retrieve the first valid IPv4 address from a list
function Get-FirstIPv4 {
    param([object]$IpList)
    $ips = @($IpList) | Where-Object { $_ -and $_.Trim().Length -gt 0 }
    if ($ips.Count -eq 0) { return $null }
    $ipv4 = $ips | Where-Object { $_ -match '^\d{1,3}(\.\d{1,3}){3}$' } | Select-Object -First 1
    if ($ipv4) { return $ipv4 }
    return $null
}

# Prompt User to connect to vCenter Server
$vCenterUser = Read-Host "Enter your user name (DOMAIN\User or user@domain.com)"

# Prompt Password to connect to the vCenter Server
$vCenterUserPassword = Read-Host "Enter your password (no worries it is a secure string)" -AsSecureString:$true

# Collect username and password as credentials
$Credentials = New-Object System.Management.Automation.PSCredential -ArgumentList $vCenterUser, $vCenterUserPassword

# List of vCenter Servers to connect to
$vCenterList = @("lbn-vcenter-01.ad.lbn.fr",
			"lbn-vcenter-02.ad.lbn.fr",
			"lbn-vcenter-05.ad.lbn.fr",
			"aka-vcenter-01.ad.lbn.fr")

# Connect to each vCenter and process VMs
ForEach ($vCenter in $vCenterList) {
    Connect-VIServer -Server $vCenter -Credential $Credentials -ErrorAction Ignore | Out-Null

    If ($? -Eq $True) {
        Write-Host "Connected to your vCenter server $vCenter" -ForegroundColor Green
        Write-Host "Processing Virtual Machine Inventory on vCenter $Vcenter..." -ForegroundColor Green
    
    # Get all VMs in this vCenter except vCLS VMs
    $vms = Get-VM | where-object { $_.Name -notmatch "vCLS" }

    $i = 0
    foreach ($vm in $vms) {
        $i++
        Write-Progress -Activity "Exporting NICs" -status "VM: $($vm.Name)" -PercentComplete ([int](($i / [math]::Max($vms.Count, 1)) * 100))

        # Guest net info (can be null if Tools not running)
        $guestNets = @($vm.Guest.ExtensionData.Net)

        # All NICs from the VM
        $adapters = @(Get-NetworkAdapter -VM $vm)

        foreach ($nic in $adapters) {
            # Normalize PortGroup & MAC
            $pg = $null
            try {
                if ($nic.NetworkName -and ($nic.NetworkName.Trim()).Length -gt 0) { $pg = $nic.NetworkName.Trim() }
            }
            catch { $pg = $null }

            $mac = $null
            if ($nic.MacAddress -and ($nic.MacAddress.Trim()).Length -gt 0) { $mac = $nic.MacAddress.Trim() }

            # Match a guest net entry by MAC to get IP addresses
            $g = $null
            if ($mac) {
                $g = $guestNets | Where-Object {
                    $_.MacAddress -and ($_.MacAddress.Trim().ToLower() -eq $mac.ToLower())
                } | Select-Object -First 1
            }

            $ipv4 = $null
            if ($g) {
                $ipv4 = Get-FirstIPv4 -IpList $g.IpAddress
            }

            $row = [PSCustomObject]@{
                VM          = $vm.Name
                LBNREF      = $VM.CustomFields.Item('LBNREF')
                vCenter     = $vm.Uid.Split('@')[1].Split('.ad.lbn.fr')[0]
                PowerState  = $VM.PowerState
                NumCpu      = $VM.NumCpu
                MemGB       = $VM.MemoryGB
                NumNic      = ($VM | Get-NetworkAdapter).count
                DiskSizeGB  = $VM | Get-HardDisk | measure-object -property CapacityGB -sum | select-object -expand sum
                AdapterName = $nic.Name
                PortGroup   = $pg
                MacAddress  = $mac
                IPv4        = $ipv4
                Connected   = $nic.ConnectionState.Connected
                VIRTUALTAG  = $VM.CustomFields.Item('VIRTUALTAG')
            }
            
        $allRows.Add($row) | Out-Null
        }
    }
    Disconnect-VIServer -server $vCenter -Confirm:$false
	Write-Host "Disconnected from your vCenter Server $vCenter - have a great day :)" -ForegroundColor Green
    }
    else {
        Write-Host "Could not connect to vCenter Server $vCenterServer with user $vCenterUser" -ForegroundColor Red
    }
}
Write-Host "Exporting to csv file..." -ForegroundColor blue
Write-Host "Export file named "$Outputfile".csv is available at "$OutputPath" location" -ForegroundColor blue

$allRows | Export-Csv ("$OutputPath" + "$Outputfile.csv") -NoTypeInformation -UseCulture

