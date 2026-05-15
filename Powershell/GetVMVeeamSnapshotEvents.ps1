<#
.SYNOPSIS
  Checks whether VMs have had a Veeam-related snapshot creation event in the last N days.

.DESCRIPTION
  Scans vCenter events between (Now - Days) and Now, finds snapshot creation events,
  then flags VMs that have evidence of Veeam (by username).

  Evidence sources:
   - VMware.Vim.VmSnapshotCreatedEvent "snapshot creation event"
   - Task/Event messages containing "Create virtual machine snapshot"

.NOTES
  - Relies on vCenter event retention. If your VC purges events sooner than N days,
#>

param(
  [Parameter(Mandatory=$true)]
  [string]$vCenter,

  # Optional CSV export path
  [string]$ExportCsv
)

# --- Connect
Connect-VIServer -Server $vCenter | Out-Null

$start = (Get-Date).AddDays(-7)
$end   = Get-Date

# --- Event collector (scalable) based on EventManager pattern
$serviceInstance = Get-View ServiceInstance
$eventMgr        = Get-View $serviceInstance.Content.EventManager

$efilter = New-Object VMware.Vim.EventFilterSpec
$efilter.Time = New-Object VMware.Vim.EventFilterSpecByTime
$efilter.Time.BeginTime = $start
$efilter.Time.EndTime   = $end

# Scope to all inventory under root folder (covers all VMs)
$efilter.Entity = New-Object VMware.Vim.EventFilterSpecByEntity
$efilter.Entity.Entity    = $serviceInstance.Content.RootFolder
$efilter.Entity.Recursion = "all"

$collector = Get-View ($eventMgr.CreateCollectorForEvents($efilter))

$batchSize = 1000

# Store latest Veeam-snapshot evidence per VM
$vmLastEventTime = @{}
$vmLastEvidence  = @{}

do {
  $events = $collector.ReadNextEvents($batchSize)

  foreach ($e in $events) {

    # Identify Veeam evidence by username or message
    $isVeeam =
      ($e.UserName -match 'usr_veeam_backup') -and
      ($e.FullFormattedMessage -match 'Create virtual machine snapshot')

    if (-not $isVeeam) { continue }

    # Map event -> VM
    if ($null -ne $e.Vm -and [string]::IsNullOrWhiteSpace($e.Vm.Name) -eq $false) {
      $vmName = $e.Vm.Name

      if (-not $vmLastEventTime.ContainsKey($vmName) -or $e.CreatedTime -gt $vmLastEventTime[$vmName]) {
        $vmLastEventTime[$vmName] = $e.CreatedTime
        $vmLastEvidence[$vmName]  = $e.FullFormattedMessage + " Taken By " +  $e.UserName
      }
    }
  }

} while ($events.Count -gt 0)

$collector.DestroyCollector()

# --- Build report
$vms = Get-VM  | ? {$_.Name -notmatch "vCLS" -and $_.PowerState -eq "PoweredOn"}

$now = Get-Date

$report = foreach ($vm in $vms) {
  $last = $vmLastEventTime[$vm.Name]

  [pscustomobject]@{
    VMName                 = $vm.Name
	LBNREF     			   = $vm.CustomFields.Item('LBNREF')
    PowerState             = $vm.PowerState
    BackedUpLastNDays      = [bool]$last
    LastVeeamSnapshotEvent = $last
    Evidence               = if ($last) { $vmLastEvidence[$vm.Name] } else { $null }
  }
}

# Sort: “not backed up” first, then oldest evidence
$report = $report | Sort-Object BackedUpLastNDays, AgeDays -Descending:$false

# Output to console
$report | format-table

# Optional export
if ($ExportCsv) {
  $report | Export-Csv -NoTypeInformation -Encoding UTF8 -Path $ExportCsv
  Write-Host "Exported to: $ExportCsv"
}

Disconnect-VIServer -Confirm:$false
