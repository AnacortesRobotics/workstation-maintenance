#Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
$Executable = "choco.exe"

if (Get-Command $Executable -ErrorAction SilentlyContinue)
{
   $CurrentVersion = [System.Version](choco.exe --version)
   Write-Host $CurrentVersion
   $MinimumVersion = [System.Version]"2.2.0"

   $RequiredVersion = [System.Version]$MinimumVersion

   If ($CurrentVersion -lt $RequiredVersion)
   {
        Write-Host "$($Executable) version $($CurrentVersion) does not meet requirements. Upgrading ..."
   }
   else {
        Write-Host "$($Executable) version $($CurrentVersion) meets requirements, greater than $($MinimumVersion). No action taken."
   }
}
else {
    Write-Host "Unable to find $($Executable) in your PATH. Installing ..."
}