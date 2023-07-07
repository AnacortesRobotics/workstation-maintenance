<#
.SYNOPSIS
    This script helps Anacortes Robotics teams maintain their team workstations. It uses Chocolatey to
    install and/or upgrade software on each machine

.DESCRIPTION
    A more detailed description of why and how the function works.

.INPUTS
    (Optional)ConfigFile - defaults to current directory "choco_packages.json"
    (Optional)ChocoSource - defaults to "https://community.chocolatey.org/api/v2/"

.OUTPUTS
    Output of choco install commands

.EXAMPLE
    The example calls the script in the local file, and saves csv files to child directory "reports\"
    PS C:\> .\choco_install.ps1
    PowerShell.exe -File "choco_install" -ConfigFile "choco_packages.json" -ChocoSource "D:\choco_install_pkgs_2023-06-30"
    Invoke-Expression '.\choco_install.ps1  -ConfigFile "choco_packages.json"

.NOTES
    Author: Coach Jenkins
    For: Anacortes Robotics FTC Team 7198
    Last Edit: 07-07-2023
    Version 1.0/06-25-2023 - initial release, capable of running choco install with package.config xml file
    Version 1.1/07-07-2023
      * Add ability to use a json file as choco packages.config style file, instead of XML
      * Pass into script which config file to use (json or xml), and what source is for packages
    # Got ideas from:
    # https://gist.github.com/apfelchips/792f7708d0adff7785004e9855794bc0
    # Youtube video on hook scripts...

    # What's left as of 6/25/2023

    ### Does not work - need to develop new community package
    #    <package id="revrobotics-hardwareclient" source="https://community.chocolatey.org/api/v2/"
    #        version="1.5.3"
    #        allowMultipleVersions="false" ignoreDependencies="false"
    #    />

    # freecad is not installed into InstallDir parameter, need to fix in package.config
    # Need to add IntelliJ, then make sure env vars are all correct
    # need to make community package for Ev3 Classroom or newest Spike Classroom?

#>


# default parameters to choco community and json packages config file
param (
    [String]$ConfigFile = "choco_packages.json",
    [String]$ChocoSource = "https://community.chocolatey.org/api/v2/"
)

function ProcessConfig-Json {
    <#
    .SYNOPSIS
        Extract data from json config file and execute installs as appropriate.

    .DESCRIPTION
        Converts json data from config file, sets up choco install commands, runs the install.

    .INPUTS
        Name/Path of json config file.
        Source location for choco packages.

    .OUTPUTS
        None.

    .EXAMPLE
        ProcessConfig-Json $configfile $source
    #>
    param(
        [Parameter()]
        [String] $config,
        [String] $source
    )

    Write-Output "config=$config, source=$source"
    $JsonObject = Get-Content -Path $config -Raw | ConvertFrom-Json
    foreach ($package in $JsonObject.packages) {
        $arguments = (' --source="'+$source+'" --verbose --debug')
        $package.PSObject.Properties.Value | Get-Member -Type properties | foreach name | foreach {
            $value = $package.PSObject.Properties.Value.$_
            # put id in the front of the argument string
            if ($_ -eq "id") {
                $str = $("choco install " + $value)
                $arguments = $str + $arguments
            }
            # add argument to end of arguments string
            else {
                $str = $(" --" + $_ + '=' + $value)
                $arguments += $str
            }
        }
    }
    Write-Output $arguments
    Invoke-Expression  $arguments
}

function ProcessConfig-XML {
    <#
    .SYNOPSIS
        Extract data from XML config file and execute installs as appropriate.

    .DESCRIPTION
        Pass XML config file to choco install command and run it.

    .INPUTS
        Name/Path of XML config file.
        Source location for choco packages.

    .OUTPUTS
        None.

    .EXAMPLE
        ProcessConfig-XML $configfile $source
    #>
    param(
        [Parameter()]
        [String] $config,
        [String] $source
    )

    Write-Output "config=$config, source=$source"
    choco install $config --source="""$source""" --verbose --debug
}

# Set the execution policy for this run only
# Set-ExecutionPolicy RemoteSigned
# Set-ExecutionPolicy Bypass -Scope Process -Force

# Check Permissions
# if ( -Not( (New-Object Security.Principal.WindowsPrincipal $([Security.Principal.WindowsIdentity]::GetCurrent())).IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)) ){
#     Write-Error -Message "Script needs Administrator permissions"
#     exit 1
# }

if (-Not (Get-Command "choco" -errorAction SilentlyContinue)) {
   [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
   iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
}

# Generally setup code using Admin privileges
choco feature enable -n=allowGlobalConfirmation

# Test that packages.config exists with this file
if (Test-Path -Path $ConfigFile) {
    if ([System.IO.Path]::GetExtension($ConfigFile) -eq ".json" ) {
        Write-Output "parameter is json file"
        ProcessConfig-Json -config $ConfigFile -source $ChocoSource
    }
    elseif ([System.IO.Path]::GetExtension($ConfigFile) -eq ".config" ) {
        Write-Output "parameter is config file"
        ProcessConfig-XML -config $ConfigFile -source $ChocoSource
    }

}
else {
    Write-Error -Message "Config file is missing: $ConfigFile"
}
