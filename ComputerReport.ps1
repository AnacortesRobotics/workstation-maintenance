# Anacortes Robotics
# Report on workstations (FTC + FLL Challenge)
# Author: Coach Jenkins
# Created: 6/25/2023
# Version: 1.0

# Generic variables
$delimiter = '|'
$currentDate = Get-Date -Format 'yyyy-MM-dd'
$currentPath = $PWD.Path + '\reports'

Write-Host ""
Write-Host ""

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

$DeviceInfo = [pscustomobject]$Properties

$DeviceInfo

#Get List of Installed Apps

$excludedPublishers = @('NVIDIA*','Conexant*','Microsoft*')
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

$csvDevicePath = "$($currentPath)\$($DeviceInfo.Device)-Report-Device-$($currentDate).csv"

# clear the output file first
if (Test-Path -Path $csvDevicePath) {
    Clear-Content -Path $csvDevicePath
}
# get the desired field, convert to CSV string, 
# remove lines with only delimiter characters (empty...), remove double quotes, output the file
$DeviceInfo |
    ConvertTo-Csv -Delimiter $delimiter -NoTypeInformation | %{$_ -replace '"',''} |
    Where-Object { $_ -notmatch '^(.)\1*$'} |
    Out-File -FilePath $csvDevicePath -Append -Encoding utf8



$csvAppsPath = "$($currentPath)\$($DeviceInfo.Device)-Report-InstalledApps-$($currentDate).csv"

# clear the output file first
if (Test-Path -Path $csvAppsPath) {
    Clear-Content -Path $csvAppsPath
}
# get the desired field, convert to CSV string, 
# remove lines with only delimiter characters (empty...), remove double quotes, output the file
$filteredInstalledApps | Select-Object Publisher,DisplayName,DisplayVersion,InstallDate | 
    Sort-Object -Property Publisher |
    ConvertTo-Csv -Delimiter $delimiter -NoTypeInformation | %{$_ -replace '"',''} |
    Where-Object { $_ -notmatch '^(.)\1*$'} |
    Out-File -FilePath $csvAppsPath -Append -Encoding utf8
