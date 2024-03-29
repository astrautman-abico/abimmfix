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


# Read beacon.abimm.com/grouplist.json
$json = invoke-RestMethod -Uri $URI

if (!($null -eq $json)){
    # Find matching computername and group assigment
    $ComputerObj = $json | where-Object hostname -eq $env:COMPUTERNAME

    if ($null -eq $ComputerObj) {
        Set-OrAddIniValue -FilePath c:\windows\syswow64\application_handler\settings.ini -keyValueList @{ KeepAlive = " KeepAlive.htm"}
    } else {
        $GroupAssignment = $ComputerObj.group
        
        # Set Environment Variable to equal group assignment
        Setx TerminalGroupAssignment $GroupAssignment /M
        
        # Rewrite Apphandler settings ini to match group assignment
        Set-OrAddIniValue -FilePath c:\windows\syswow64\application_handler\settings.ini -keyValueList @{ KeepAlive = " Group$($GroupAssignment).htm"}
    }
}