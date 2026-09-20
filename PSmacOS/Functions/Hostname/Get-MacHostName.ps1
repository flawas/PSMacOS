<#
    .SYNOPSIS
        Get the host name information of the local macOS system.

    .DESCRIPTION
        Return the ComputerName (Finder / AirDrop display name), the
        LocalHostName (Bonjour .local name) and the HostName (Unix host name)
        system configuration keys, read with the scutil command line tool, as
        well as the effective DNS host name reported by .NET.

    .INPUTS
        None.

    .OUTPUTS
        PSmacOS.HostName. Host name information of the local macOS system.

    .EXAMPLE
        PS /> Get-MacHostName
        Get the host name information of the local macOS system.

    .LINK
        https://github.com/flaviowaser/PSmacOS
#>
function Get-MacHostName
{
    [CmdletBinding()]
    [OutputType('PSmacOS.HostName')]
    param ()

    # Exit if executed on a non-macOS platform
    if ($PSVersionTable.PSVersion.Major -gt 5 -and -not $IsMacOS)
    {
        throw 'This function is only supported on macOS platforms.'
    }

    $hostName = [PSCustomObject] @{
        PSTypeName    = 'PSmacOS.HostName'
        ComputerName  = Get-ScutilValue -Key 'ComputerName'
        LocalHostName = Get-ScutilValue -Key 'LocalHostName'
        HostName      = Get-ScutilValue -Key 'HostName'
        DnsHostName   = [System.Net.Dns]::GetHostName()
    }

    Write-Output $hostName
}
