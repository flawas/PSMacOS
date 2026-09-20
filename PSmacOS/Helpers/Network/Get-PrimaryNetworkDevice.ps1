<#
    .SYNOPSIS
        Get the device of the current default route.

    .DESCRIPTION
        Parse the output of 'route -n get default' to determine the network
        device currently used for the default route, i.e. the primary
        network interface.

    .INPUTS
        None.

    .OUTPUTS
        System.String. Device name of the primary network interface, or
        $null if no default route exists.

    .EXAMPLE
        PS /> Get-PrimaryNetworkDevice
        Get the device of the current default route.
#>
function Get-PrimaryNetworkDevice
{
    [CmdletBinding()]
    [OutputType([System.String])]
    param ()

    $lines = & route -n get default 2>$null

    if ($LASTEXITCODE -ne 0)
    {
        return
    }

    foreach ($line in $lines)
    {
        if ($line -match '^\s*interface: (?<Value>.+)$')
        {
            Write-Output $Matches.Value
            return
        }
    }
}
