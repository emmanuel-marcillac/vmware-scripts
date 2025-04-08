########################################################################
###
### Remove vm snapshot older then x days but keep VEEAM backup snapshots
###
########################################################################

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

# Define the cutoff date as 7 days ago from today
    $cutoffDate = (Get-Date).AddDays(-0)

# Retrieve all snapshots from all VMs
    $snapshots = Get-VM -name EMA-PACKER | Get-Snapshot -ErrorAction SilentlyContinue

    foreach ($snapshot in $snapshots) {
        # Check if the snapshot is older than 7 days and its name does not contain "VEEAM"
        if (($snapshot.Created -lt $cutoffDate) -and ($snapshot.Name -notmatch "VEEAM BACKUP TEMPORARY SNAPSHOT")) {
            Write-Host "Removing snapshot '$($snapshot.Name)' from VM '$($snapshot.VM.Name)' created on $($snapshot.Created)" -ForegroundColor Cyan
        # Remove the snapshot; using -Confirm:$false to bypass confirmation
            Remove-Snapshot -Snapshot $snapshot -Confirm:$false -RunAsync
    }
        else {
        Write-Host "Skipping snapshot '$($snapshot.Name)' for VM '$($snapshot.VM.Name)'." -ForegroundColor Yellow
    }
}
}
else {
	Write-Host "Cannot complete login on $vCenterServer due to an incorrect user name or password" -ForegroundColor Red
}