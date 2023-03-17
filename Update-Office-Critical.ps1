Function Get-OfficeVersion{
    $Version = [Version]::New(16, 0, 16130, 20306)
    $OfficeVersion = [version]::new((Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Office\ClickToRun\Configuration' -Name ClientXnoneVersion | Select-Object ClientXnoneVersion).ClientXnoneVersion)
    
    [PSCustomObject]@{
        ComputerName  = $env:COMPUTERNAME
        OfficeVersion = $OfficeVersion
        UpToDate      = if($OfficeVersion -ge $Version){$True}else{$false}
    }
}

Function Write-Log {
    param (
        [Parameter(Mandatory = $True, Position=0)]
        [array] $LogOutput,
        [Parameter()]
        [string] $Path = "$env:TEMP\ABICO-CriticalOfficeUpdates.log"
    )

    if(!($Path)){ 
        New-Item -Path $Path -Type File
    }

    $currentDate = (Get-Date -UFormat "%d-%m-%Y")
    $currentTime = (Get-Date -UFormat "%T")
    $logOutput = $logOutput -join (" ")
    "[$currentDate $currentTime] $logOutput" | Out-File $Path -Append
}

write-log "Starting..."

$UpdateStatus = Get-OfficeVersion

Write-Log "ComputerName: $($updatestatus.Computername) | OfficeVersion: $($Updatestatus.officeversion) | Uptodate: $($UpdateStatus.UpToDate)"

if (!($UpdateStatus.Uptodate)){
    # Temporarily disable Windows Update for Business deferral period
    $wufbRegPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate"
    $wufbValue = (Get-ItemProperty -Path $wufbRegPath -Name DeferQualityUpdatesPeriodInDays -ErrorAction SilentlyContinue).DeferQualityUpdatesPeriodInDays
    if ($null -ne $wufbValue) {
        if ($wufbValue -ne 0) {
            write-log "Disabling Windows Update for Business deferral period"
            Set-ItemProperty -Path $wufbRegPath -Name DeferQualityUpdatesPeriodInDays -Value 0
        }
        else {
            write-log "WUfB deferral period already zero"
        }
    }

    # Update Office 365 and 2019 products
    if (Test-Path "C:\Program Files\Common Files\microsoft shared\ClickToRun\OfficeC2RClient.exe") {
        write-log "Click-To-Run Office detected. Initiating update."
        & "C:\Program Files\Common Files\microsoft shared\ClickToRun\OfficeC2RClient.exe" /update user displaylevel=false forceappshutdown=true
    }
    else {
        write-log "No Click-To-Run Office detected."
    }

    # Return DeferQualityUpdatesPeriodInDays to previous value
    if ($null -ne $wufbValue) {
        write-log "Enabling Windows Update for Business deferral period"
        Set-ItemProperty -Path $wufbRegPath -Name DeferQualityUpdatesPeriodInDays -Value $wufbValue
    }
} else {
    Write-Log "Office is currently the latest version."
}

Write-Log "Done!"