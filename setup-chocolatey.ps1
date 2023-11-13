$Executable = "choco.exe"
$MinimumVersion = [System.Version]"2.2.0"
$elevated = ([Security.Principal.WindowsPrincipal] `
 [Security.Principal.WindowsIdentity]::GetCurrent()
).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

# Get the most recent chocolatey msi installer file
$InstallFile=(Get-ChildItem "..\*" -Filter choco*.msi -recurse  | sort LastWriteTime | select -last 1).FullName
Write-Host $InstallFile

function runMSI {
    $DataStamp = get-date -Format yyyyMMddTHHmmss
    $DataStamp = get-date -Format yyyyMMddTHHmmss
    $logFile = '{0}-{1}.log' -f $Executable,$DataStamp
    $MSIArguments = @(
        "/i"
        ('"{0}"' -f $InstallFile)
        "/norestart"
        "/L*v"
        $logFile
    )
    $installed = Start-Process "msiexec.exe" -ArgumentList $MSIArguments -Wait -NoNewWindow
    Write-Host $installed
}

if (! $elevated) {
    Write-Host "This script needs to be run in adminstorator account which this is not. Cancelling run."
    Exit 0
}
if (Get-Command $Executable -ErrorAction SilentlyContinue)
{
    $CurrentVersion = [System.Version](Start-Process "$($Executable)" -ArgumentList "--version" -Wait -NoNewWindow)
    Write-Host $CurrentVersion

    $RequiredVersion = [System.Version]$MinimumVersion

    If ($CurrentVersion -lt $RequiredVersion)
    {
        Write-Host "$($Executable) version $($CurrentVersion) does not meet requirements. Upgrading ..."
        runMSI
        Write-Host "restart machine to get it to recognize choco commands"
    }
    else {
        Write-Host "$($Executable) version $($CurrentVersion) meets requirements, greater than $($MinimumVersion). No action taken."
    }
}
else {
    Write-Host "Unable to find $($Executable) in your PATH. Installing ..."
#
    runMSI
    Write-Host "restart machine to get it to recognize choco commands"
}

# Add local source pointing to assets directory of local nupkg files.
choco source add --name="local" --source="assets\" --priority=1

