function Set-OrAddIniValue{
    Param(
        [string]$FilePath,
        [hashtable]$keyValueList
    )

    $content = Get-Content $FilePath

    $keyValueList.GetEnumerator() | ForEach-Object {
        if ($content -match "^$($_.Key)=")
        {
            $content= $content -replace "^$($_.Key)=(.*)", "$($_.Key)=$($_.Value)"
        }
        else
        {
            $content += "$($_.Key)=$($_.Value)"
        }
    }

    $content | Set-Content $FilePath
}

$URI = 'https://beacon.abimm.com/momoa.html'

# make sure this is running on a terminal
$Regkey = Get-ItemProperty HKLM:\software\Microsoft\Windows\CurrentVersion\OEMInformation\ | Select-String 'Terminal'
if (!($Regkey)){
    "Not a Terminal"
    exit 1
}

# Make sure internet connectivity
if (!(Test-NetConnection 'google.com')){
    "Not on the internet"
    exit 1
}

# Make sure can reach beacon.abimm.com
if (!(Test-NetConnection 'beacon.abimm.com')){
    "Can't reach Beacon"
    exit 1
}

# Read beacon.abimm.com/grouplist.json
$json = invoke-RestMethod -Uri $URI

# Find matching computername and group assigment
$ComputerObj = $json | where-Object hostname -eq $env:COMPUTERNAME
$GroupAssignment = $ComputerObj.group

# Verify beacon.abimm.com/groupX.htm exists
try {
    $WebTest = invoke-restmethod -uri "https://beacon.abimm.com/Group$($GroupAssignment).htm"
} Catch {
    "Can't reach assigned group page."
    exit 1
}

# Set Environment Variable to equal group assignment
Setx TerminalGroupAssignment $GroupAssignment /M

# Rewrite Apphandler settings ini to match group assignment
Set-OrAddIniValue -FilePath c:\windows\syswow64\application_handler\settings.ini -keyValueList @{ KeepAlive = " Group$($GroupAssignment)"}