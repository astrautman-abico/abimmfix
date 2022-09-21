# Create the new custom shells.

# Create Handles
$COMPUTER = "localhost"
$NAMESPACE = "root\standardcimv2\embedded"

# This well-known security identifier (SID) corresponds to the BUILTIN\Administrators group.

$Admins_SID = "S-1-5-32-544"

# Create a function to retrieve the SID for a user account on a machine.

function Get-UsernameSID($AccountName) {

    $NTUserObject = New-Object System.Security.Principal.NTAccount($AccountName)
    $NTUserSID = $NTUserObject.Translate([System.Security.Principal.SecurityIdentifier])

    return $NTUserSID.Value

}

# Get the SID for a user account named "User". 

$User_SID = Get-UsernameSID("User")

$ShellLauncherClass = [wmiclass]"\\$COMPUTER\${NAMESPACE}:WESL_UserSetting"

#If Shell Already Exists, Remove it
$NTUser_Shell = Get-WmiObject -namespace $NAMESPACE -computer $COMPUTER -class WESL_UserSetting

if ($NTUser_Shell) {
"`Custom shells already set removing it"
$ShellLauncherClass.RemoveCustomShell($User_SID)
$ShellLauncherClass.RemoveCustomShell($Admins_SID)
}

# Define Behaviors
$restart_shell = 0
$restart_device = 1
$shutdown_device = 2

# Create Shell
$ShellLauncherClass.SetCustomShell($User_SID, "powershell.exe -ExecutionPolicy Bypass -WindowStyle Hidden -File c:\scripts\start.ps1", ($null), ($null), $restart_device)

$ShellLauncherClass.SetCustomShell($Admins_SID, "explorer.exe")

#Show Current Shell Objects

"`nCurrent settings for custom shells:"
Get-WmiObject -namespace $NAMESPACE -computer $COMPUTER -class WESL_UserSetting | Select Sid, Shell, DefaultAction | out-host

#Enable Shell Launcher

$ShellLauncherClass.SetEnabled($TRUE)

$IsShellLauncherEnabled = $ShellLauncherClass.IsEnabled()

"`nEnabled is set to " + $IsShellLauncherEnabled.Enabled

#Write-Host "Kiosk Mode Enabled. Press Any Key To Continue"

#$x = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")

add-type -AssemblyName presentationcore,presentationframework
$ButtonType = [System.Windows.MessageBoxButton]::OK
$MessageboxTitle = "Kiosk Mode"
$MessageboxBody = "Kiosk Mode Is Now Enabled"
#$MessageIcon = [System.Windows.MessageBoxImage]::Informational
[System.Windows.MessageBox]::Show($MessageboxBody,$MessageboxTitle,$ButtonType)