[![GitHub Release](https://img.shields.io/github/v/release/flaviowaser/PSmacOS?label=Release&logo=GitHub&sort=semver)](https://github.com/flaviowaser/PSmacOS/releases)
[![GitHub CI Build](https://img.shields.io/github/actions/workflow/status/flaviowaser/PSmacOS/pwsh-ci.yml?label=CI%20Build&logo=GitHub)](https://github.com/flaviowaser/PSmacOS/actions/workflows/pwsh-ci.yml)
[![PowerShell Gallery Version](https://img.shields.io/powershellgallery/v/PSmacOS?label=PowerShell%20Gallery&logo=PowerShell)](https://www.powershellgallery.com/packages/PSmacOS)
[![Gallery Downloads](https://img.shields.io/powershellgallery/dt/PSmacOS?label=Downloads&logo=PowerShell)](https://www.powershellgallery.com/packages/PSmacOS)

# PSmacOS PowerShell Module

PowerShell module with custom functions and cmdlets to manage macOS system
settings, starting with the local host name.

## Introduction

macOS actually knows three different host name keys: the **ComputerName**,
the friendly name shown in Finder, AirDrop and sharing dialogs; the
**LocalHostName**, the Bonjour name used for the `.local` mDNS address; and
the **HostName**, the classic Unix host name. All three are usually kept in
sync by System Settings, but can drift apart, for example after a migration
or a manual `scutil` change.

With **Get-MacHostName** you can read all three values plus the effective
.NET `DnsHostName` in one call. With **Set-MacHostName** you can update them,
either all at once from a single friendly name (which is sanitized into a
valid Bonjour name for the LocalHostName and HostName), or individually.

## Features

### Hostname

* **Get-MacHostName**
  Get the ComputerName, LocalHostName, HostName and effective DnsHostName of
  the local macOS system.

* **Set-MacHostName**
  Set the ComputerName, LocalHostName and HostName of the local macOS system
  with the `scutil` command line tool. Requires an elevated (root) session,
  e.g. PowerShell started with `sudo`.

### Network

* **Get-MacNetworkInfo**
  Get one object per configured network service (as shown in System Settings
  > Network), including hardware port, MAC address, IPv4 configuration,
  Wi-Fi SSID and whether it is the currently active (default route) service.

### Application

* **Get-MacApplication**
  Get the applications installed by the user, no matter if installed via the
  Mac App Store, a signed installer or manually, including version,
  publisher, architecture and install location. The macOS default
  applications shipped with the operating system (in /System/Applications,
  e.g. Mail, Notes or Safari) are excluded by default; use `-All` to include
  them too.

### Bluetooth

* **Get-MacBluetoothDevice**
  Get all Bluetooth devices known to the system, both currently connected
  and paired-but-not-connected, including address, type and battery level.

### Account

* **Get-MacInternetAccount**
  Get the accounts configured in System Settings > Internet Accounts (e.g.
  iCloud, Google, Exchange, CalDAV/CardDAV). Reads directly from the
  accountsd database, since there is no public API for this information.
  Requires Full Disk Access for the application running PowerShell (e.g.
  Terminal, iTerm2 or Visual Studio Code) — the command opens the correct
  Privacy & Security pane and explains what to do if access is missing.

### Update

* **Install-MacSoftwareUpdate**
  Install pending macOS software updates, as reported by the `softwareupdate`
  command line tool, either all of them at once or one or more specific
  updates by label. Requires an elevated (root) session, e.g. PowerShell
  started with `sudo`.

## Versions

Please find all versions in the [GitHub Releases] section and the release
notes in the [CHANGELOG.md] file.

## Installation

Use the following command to install the module from the [PowerShell Gallery],
if the PackageManagement and PowerShellGet modules are available:

```powershell
# Download and install the module
Install-Module -Name 'PSmacOS'
```

Alternatively, download the latest release from GitHub and install the module
manually on your local system:

1. Download the latest release from GitHub as a ZIP file: [GitHub Releases]
2. Extract the module and install it: [Installing a PowerShell Module]

## Usage

```powershell
# Show the current host name information
Get-MacHostName

# Rename the Mac, applying a sanitized Bonjour name to LocalHostName and HostName
sudo pwsh -Command "Set-MacHostName -Name 'Flavios-MacBook-Pro'"

# Set only the Unix host name
sudo pwsh -Command "Set-MacHostName -HostName 'flavios-macbook-pro'"

# Show all configured network services
Get-MacNetworkInfo

# Show only the currently active (default route) network service
Get-MacNetworkInfo | Where-Object IsActive

# List user-installed applications (macOS default apps excluded)
Get-MacApplication

# List every application, including the macOS default apps
Get-MacApplication -All

# List currently connected Bluetooth devices
Get-MacBluetoothDevice | Where-Object Connected

# List configured internet accounts (requires Full Disk Access)
Get-MacInternetAccount

# Install all pending macOS software updates
sudo pwsh -Command "Install-MacSoftwareUpdate"

# Install a specific software update and restart if required
sudo pwsh -Command "Install-MacSoftwareUpdate -Name 'macOSSonomaUpdate-14.5' -RestartIfNeeded"
```

## Requirements

The following minimum requirements are recommended to use this module. It
may work on older versions too, but they are not officially supported or
tested.

* macOS
* PowerShell 7

## Contribute

Please feel free to contribute by opening new issues or providing pull
requests. For the best development experience, open this project as a folder
in Visual Studio Code and ensure that the PowerShell extension is installed.

* [Visual Studio Code] with the [PowerShell Extension]
* [Pester], [PSScriptAnalyzer] and [InvokeBuild] modules

[PowerShell Gallery]: https://www.powershellgallery.com/packages/PSmacOS
[GitHub Releases]: https://github.com/flaviowaser/PSmacOS/releases
[Installing a PowerShell Module]: https://learn.microsoft.com/en-us/powershell/scripting/developer/module/installing-a-powershell-module

[CHANGELOG.md]: CHANGELOG.md

[Visual Studio Code]: https://code.visualstudio.com/
[PowerShell Extension]: https://marketplace.visualstudio.com/items?itemName=ms-vscode.PowerShell
[Pester]: https://www.powershellgallery.com/packages/Pester
[PSScriptAnalyzer]: https://www.powershellgallery.com/packages/PSScriptAnalyzer
[InvokeBuild]: https://www.powershellgallery.com/packages/InvokeBuild
