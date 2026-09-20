<#
    .SYNOPSIS
        Get the name of the currently connected Wi-Fi network.

    .DESCRIPTION
        Parse the output of 'networksetup -getairportnetwork' for the given
        Wi-Fi device. Returns $null if the device is not associated with a
        Wi-Fi network.

    .INPUTS
        None.

    .OUTPUTS
        System.String. Name (SSID) of the connected Wi-Fi network, or $null.

    .EXAMPLE
        PS /> Get-WiFiNetworkName -Device 'en0'
        Get the name of the Wi-Fi network the device en0 is connected to.
#>
function Get-WiFiNetworkName
{
    [CmdletBinding()]
    [OutputType([System.String])]
    param
    (
        # Name of the Wi-Fi device, e.g. en0.
        [Parameter(Mandatory = $true)]
        [System.String]
        $Device
    )

    $lines = & networksetup -getairportnetwork $Device 2>$null

    foreach ($line in $lines)
    {
        if ($line -match '^Current Wi-Fi Network: (?<Value>.+)$')
        {
            Write-Output $Matches.Value
            return
        }
    }
}
