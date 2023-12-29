# workstation-maintenance
Scripts and tools to maintain robotics team workstation software from year to year

### Decisions:
**License:** Use BSD-3 license because that's what FIRST uses for github.com/ftcrobotcontroller which provides our purpose...

### Explanation
The powershell script ***ComputerReport.ps1*** can be run from the command line on any Windows workstation. 
It collects information about the workstation include name, about info, user accounts, and installed applications.
It takes several optional parameters, see the file comments for more information.

The powershell script ***setup-chocolatey.ps1*** installs and/or upgrades chocolatey. It needs to be run from PS command line in Administrator mode using
```
PS> powershell -ExecutionPolicy ByPass -File .\setup_chocolatey.ps1
```

The powershell script ***choco_install.ps1*** can be run from the command line on any Windows workstation.
It installs or upgrades applications stored in packages.config.
