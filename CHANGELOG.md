# Changelog

All notable changes to this project will be documented in this file.

The format is mainly based on [Keep a Changelog](http://keepachangelog.com/)
and this project adheres to [Semantic Versioning](http://semver.org/).

## Unreleased

* Added: New function to get network interface information of the local macOS system (Get-MacNetworkInfo)
* Added: New function to get installed applications, excluding macOS default apps unless -All is used (Get-MacApplication)
* Added: New function to get paired Bluetooth devices (Get-MacBluetoothDevice)
* Added: New function to get configured internet accounts, e.g. iCloud or Google (Get-MacInternetAccount)
* Added: New function to install pending macOS software updates (Install-MacSoftwareUpdate)
* Added: New function to send pipeline output to an interactive, searchable list window, similar to the Windows PowerShell Out-GridView cmdlet (Out-MacGridView)

## 1.0.0 - 2026-09-16

* Added: Initial release
* Added: New function to get the host name information of the local macOS system (Get-MacHostName)
* Added: New function to set the host name of the local macOS system (Set-MacHostName)
