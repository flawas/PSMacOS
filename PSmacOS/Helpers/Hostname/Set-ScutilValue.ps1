<#
    .SYNOPSIS
        Set a system configuration value with scutil.

    .DESCRIPTION
        Wrap the macOS scutil command line tool to write one of the system
        configuration host name keys. Requires root privileges.

    .INPUTS
        None.

    .OUTPUTS
        None.

    .EXAMPLE
        PS /> Set-ScutilValue -Key 'ComputerName' -Value 'Flavios-MacBook-Pro'
        Set the computer name.
#>
function Set-ScutilValue
{
    [CmdletBinding()]
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '')]
    param
    (
        # Name of the system configuration key to write.
        [Parameter(Mandatory = $true)]
        [ValidateSet('ComputerName', 'LocalHostName', 'HostName')]
        [System.String]
        $Key,

        # New value of the system configuration key.
        [Parameter(Mandatory = $true)]
        [System.String]
        $Value
    )

    & scutil --set $Key $Value

    if ($LASTEXITCODE -ne 0)
    {
        throw "Failed to set the scutil key '$Key' to '$Value'."
    }
}
