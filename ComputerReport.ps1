param (
    [String]$Delimiter = "|",
    [String]$Path = $PWD.Path + '\reports',
    [String[]]$ExcludePublishers = @('NVIDIA*','Conexant*','Microsoft*'),
    [Bool]$Exclude = $true
)
<#
.SYNOPSIS
    This script outputs reports on Windows workstations (FTC + FLL Challenge) including device info,
    installed apps, and user accounts. This script helps Anacortes Robotics teams maintain their
    team workstations.

.DESCRIPTION
    A more detailed description of why and how the function works.

.INPUTS
    (Optional)Delimiter - defaults to "|"
    (Optional)Path - directory to output report files to, defaults to <current directory>\reports
    (Optional)ExcludePublishers
    (Optional)Exclude - value is $true or $false, $true will test each publisher to be excluded

.OUTPUTS
    Generates separate csv files for device info, installed apps, user accounts.

.EXAMPLE
    The example calls the script in the local file, and saves csv files to child directory "reports\"
    PS C:\> .\ComputerReport.ps1
    PowerShell.exe -File "ComputerReport.ps1" -ExecutionPolicy Bypass
    Invoke-Expression '.\ComputerReport.ps1 -Exclude $false'
    ** Test these on machine with ExecutionPolicy=Restricted and clean up command

.NOTES
    Author: Coach Jenkins
    Last Edit: 07-02-2023
    Version 1.0/06-25-2023 - initial release, capable of collecting device info and installed apps
    Version 1.1/07-02-2023
      * Add output of all users on workstation
      * Cleanup ComputerReport.ps1 file (breaking up code into functions) in order to read more easily
      * Add documentation comment blocks to functions and program
      * Add device name and current date to every row in every csv file so the data will merge more easily
#>

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
    param(
        [Parameter()]
        [DateTime] $today
    )
    # Get Data - Device info, installed apps info
    $SysInfo = Get-ComputerInfo
    $OSInfo = Get-CimInstance Win32_OperatingSystem
    $RamInfo = (Get-CimInstance Win32_PhysicalMemory | Measure-Object -Property capacity -Sum).sum
    [Array]$DiskInfo = @(Get-WmiObject -Class Win32_LogicalDisk | ? {$_. DriveType -eq 3}) #| Select -Property deviceid, size, freespace )

    $Properties = [ordered]@{
        Device           = $SysInfo.CsDNSHostName
        Model            = $SysInfo.CsModel
        Processor        = $SysInfo.CsProcessors.Name
        InstalledRam     = ($RamInfo/1GB).ToString('#.# GB')
        SystemType       = $SysInfo.CsSystemType
        Num_Processors   = $SysInfo.CsNumberOfLogicalProcessors
        Edition          = $SysInfo.OSName
        WindowsVersion   = $SysInfo.OsDisplayVersion
        InstallDate      = $OSInfo.InstallDate
        Build            = $SysInfo.OSBuildNumber
        HotFixes         = $SysInfo.OsHotFixes
        BiosStatus       = $SysInfo.BiosStatus
        ReportDate       = $currentDate
    }

    $DeviceInfo = [PsCustomObject]$Properties

    $i = 0

    ForEach($device in $DiskInfo) {
        $devStr = $device.DeviceID -replace "\W"
        New-Variable -Name "TotalDiskSpace$devStr" -Value ([Math]::Round(($device.Size/1GB),2)).ToString('#.# GB')
        New-Variable -Name "FreeDiskSpace$devStr" -Value ([Math]::Round(($device.FreeSpace/1GB),2)).ToString('#.# GB')
        Write-Host $i "TotalDiskSpace$devStr : " (Get-Variable -Name "TotalDiskSpace$devStr").Value "FreeDiskSpace$devStr : "  (Get-Variable -Name "FreeDiskSpace$devStr").Value

        $DeviceInfo | Add-Member -Name "TotalDiskSpace$devStr" -Type NoteProperty -Value (Get-Variable -Name "TotalDiskSpace$devStr").Value
        $DeviceInfo | Add-Member -Name "FreeDiskSpace$devStr" -Type NoteProperty -Value (Get-Variable -Name "FreeDiskSpace$devStr").Value

        $i++
    }

    return $DeviceInfo

}

function Write-DataCsv {
    <#
    .SYNOPSIS
        Output PSCustomObject to Csv file.

    .DESCRIPTION
        Creates the file if it does not exist, clears content if it does exist. Writes the data to file in csv format.

    .INPUTS
        Filename prefix, nice name for custom object to put in filename, csv file delimiter, custom object variable (one or more rows)

    .OUTPUTS
        Csv file with custom object data

    .EXAMPLE
        Write-DataCsv <Filename Prefix> <Name of custom object> $delimiter $customObj
    #>
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
    }

    # get the desired field, convert to CSV string,
    # remove lines with only delimiter characters (empty...), remove double quotes, output the file
    $OutputInfo |
        ConvertTo-Csv -Delimiter $Delimiter -NoTypeInformation | %{$_ -replace '"',''} |
        Where-Object { $_ -notmatch '^(.)\1*$'} |
        Out-File -FilePath $OutputFile -Append -Encoding utf8
}

## Main
Write-Host ""
Write-Host ""

# Generic variables
$currentDate = Get-Date -Format 'yyyy-MM-dd'
$currentPath = $Path

if (-Not [bool](Get-ChildItem -Path $currentPath -ErrorAction Ignore) )
{
    #PowerShell Create directory if not exists
    New-Item $currentPath -ItemType Directory
}

$DeviceInfo = Get-DeviceInfo

#Get List of Installed Apps

$excludedPublishers = @() # create empty array
$prolificPublishers = $ExcludePublishers
if ($Exclude) {
    foreach ($pub in $prolificPublishers) {
        $confirmation = Read-Host "Ignore Publisher: '$pub' ? [y/n] "
        if ($confirmation -eq 'y') {
            $excludedPublishers += $pub
        }
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

$InstalledAppsData = $filteredInstalledApps | Sort-Object -Property Publisher |
    Select-Object @{name="Device"; expression={ $DeviceInfo.Device }},
        @{name="ReportDate"; expression={ $currentDate }},
        Publisher,DisplayName,DisplayVersion,InstallDate
     #| Format-Table
$UserData = $OutputInfo = Get-LocalUser | Sort-Object -Property Name |
    Select-Object @{name="Device"; expression={ $DeviceInfo.Device }},
        @{name="ReportDate"; expression={ $currentDate }},
        Name,PrincipalSource,Enabled,Description,LastLogon,PasswordRequired,PasswordLastSet,UserMayChangePassword,PasswordExpires,AccountExpires

Write-DataCsv "$($currentPath)\$($DeviceInfo.Device)-Report-$($currentDate)" "Device" $Delimiter $DeviceInfo
Write-DataCsv "$($currentPath)\$($DeviceInfo.Device)-Report-$($currentDate)" "InstalledApps" $Delimiter $InstalledAppsData
Write-DataCsv "$($currentPath)\$($DeviceInfo.Device)-Report-$($currentDate)" "InstalledApps" $Delimiter $InstalledAppsData
Write-DataCsv "$($currentPath)\$($DeviceInfo.Device)-Report-$($currentDate)" "Users" $Delimiter $UserData

Write-Host "Reports Complete"
$DeviceInfo
$InstalledAppsData | Format-Table
$UserData | Select-Object Name,PrincipalSource | Format-Table