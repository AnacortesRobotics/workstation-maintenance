# Anacortes Robotics
# Report on workstations (FTC + FLL Challenge)
# Author: Coach Jenkins
# Created: 06-25-2023
# Version: 1.1
# Update 1.1/07-01-2023:
#   * Add output of all users on workstation
#   * Cleanup ComputerReport.ps1 file to use functions, read more easily
#   * Add documentation to functions

# Call from commandline:
# .\ComputerReport.ps1

function Get-DeviceInfo {
    <#
    .SYNOPSIS
        Get information matching "About Device" into a custom object.

    .DESCRIPTION
        Retrieves data about the device and the windows OS for saving to file.

    .INPUTS
        None.

    .OUTPUTS
        PSCustomObject containing fields matching those of About device.

    .EXAMPLE
        $customObj = Get-DeviceInfo
    #>
    # Get Data - Device info, installed apps info
    $SysInfo = Get-ComputerInfo
    $OSInfo = Get-CimInstance Win32_OperatingSystem
    $RamInfo = (Get-CimInstance Win32_PhysicalMemory | Measure-Object -Property capacity -Sum).sum /1gb
    $DiskInfo = (Get-WmiObject -Class Win32_LogicalDisk | ? {$_. DriveType -eq 3})
    $Properties = [ordered]@{
        Device           = $SysInfo.CsDNSHostName
        Model            = $SysInfo.CsModel
        Processor        = $SysInfo.CsProcessors.Name
        InstalledRam     = $RamInfo.ToString('#.# GB')
        SystemType       = $SysInfo.CsSystemType
        Num_Processors   = $SysInfo.CsNumberOfLogicalProcessors
        Edition          = $SysInfo.OSName
        WindowsVersion   = $SysInfo.OsDisplayVersion
        InstallDate      = $OSInfo.InstallDate
        Build            = $SysInfo.OSBuildNumber
        HotFixes         = $SysInfo.OsHotFixes
        BiosStatus       = $SysInfo.BiosStatus
        TotalDiskSpace   = ($DiskInfo.Size /1GB).ToString('#.# GB')
        FreeDiskSpace    = ($DiskInfo.FreeSpace /1GB).ToString('#.# GB')
    }

    $DeviceInfo = [PsCustomObject]$Properties

    return $DeviceInfo
}

function Write-DataCsv {
    param(
        [Parameter()]
        [String] $OutputFileNamePrefix,
        [String] $OutputFilePostfix,
        [String] $Delimiter,
        [PsCustomObject] $OutputInfo
    )
    $OutputFile = "$OutputFileNamePrefix-$OutputFilePostfix.csv"

    # clear the output file first
    if (Test-Path -Path $OutputFile) {
        Clear-Content -Path $OutputFile
        Write-Host "in clear content"
    }

    # get the desired field, convert to CSV string,
    # remove lines with only delimiter characters (empty...), remove double quotes, output the file
    $OutputInfo |
        ConvertTo-Csv -Delimiter $Delimiter -NoTypeInformation | %{$_ -replace '"',''} |
        Where-Object { $_ -notmatch '^(.)\1*$'} |
        Out-File -FilePath $OutputFile -Append -Encoding utf8
}

## Main

# Generic variables
$delimiter = '|'
$currentDate = Get-Date -Format 'yyyy-MM-dd'
$currentPath = $PWD.Path + '\reports'

if (-Not [bool](Get-ChildItem -Path $currentPath -ErrorAction Ignore) )
{
    #PowerShell Create directory if not exists
    New-Item $currentPath -ItemType Directory
}

Write-Host ""
Write-Host ""


$DeviceInfo = Get-DeviceInfo

#Get List of Installed Apps

$excludedPublishers = @() # create empty array
$prolificPublishers = @('NVIDIA*','Conexant*','Microsoft*')
foreach ($pub in $prolificPublishers) {
    $confirmation = Read-Host "Ignore Publisher: '$pub' ? [y/n] "
    if ($confirmation -eq 'y') {
        $excludedPublishers += $pub
    }
}

$filteredInstalledApps = Get-ItemProperty hklm:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\* |
    Where-Object { 
        $pub = $_.Publisher
        $exclude = $false
        foreach ($excludedPublisher in $excludedPublishers) {
            if ($pub -like $excludedPublisher) {
                $exclude = $true
                break
            }
        }
        -not $exclude
    }

$filteredInstalledApps | Sort-Object -Property Publisher | Select-Object Publisher,DisplayName,DisplayVersion,InstallDate | Format-Table
$UserData = $OutputInfo = Get-LocalUser | Select *

Write-DataCsv "$($currentPath)\$($DeviceInfo.Device)-Report-$($currentDate)" "Device" $delimiter $DeviceInfo
Write-DataCsv "$($currentPath)\$($DeviceInfo.Device)-Report-$($currentDate)" "InstalledApps" $delimiter $filteredInstalledApps
Write-DataCsv "$($currentPath)\$($DeviceInfo.Device)-Report-$($currentDate)" "Users" $delimiter $UserData
