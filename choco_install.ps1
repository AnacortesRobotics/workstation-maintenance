# Anacortes Robotics
# Chocolately install script for workstations (FTC + FLL Challenge)
# Author: Coach Jenkins
# Created: 6/21/2023
# Version: 1.0

# Got ideas from:
# https://gist.github.com/apfelchips/792f7708d0adff7785004e9855794bc0
# Youtube video on hook scripts...

# Set the execution policy for this run only
Set-ExecutionPolicy RemoteSigned
Set-ExecutionPolicy Bypass -Scope Process -Force

# Check Permissions
if ( -Not( (New-Object Security.Principal.WindowsPrincipal $([Security.Principal.WindowsIdentity]::GetCurrent())).IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)) ){
    Write-Error -Message "Script needs Administrator permissions"
    exit 1
}

if (-Not (Get-Command "choco" -errorAction SilentlyContinue)) {
   [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
   iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
}


# Generally setup code using Admin privileges
choco feature enable -n=allowGlobalConfirmation

$configfile = "packages.config"
# Test that packages.config exists with this file
if (Test-Path -Path $configfile) {
    # Run the installs from the config file
    choco install $configfile -s $(pwd) --verbose --debug
} else {
    Write-Error -Message "Config file is missing: $configfile"
}

# What's left as of 6/25/2023

### Does not work - need to develop new community package
#    <package id="revrobotics-hardwareclient" source="https://community.chocolatey.org/api/v2/"
#        version="1.5.3"
#        allowMultipleVersions="false" ignoreDependencies="false"
#    />

# freecad is not installed into InstallDir parameter, need to fix in package.config

# Need to add IntelliJ and Amazon Corretto 11, then make sure env vars are all correct
# need to make community package for Ev3 Classroom or newest Spike Classroom?
