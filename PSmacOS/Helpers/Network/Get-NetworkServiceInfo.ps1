<#
    .SYNOPSIS
        Get the IPv4 configuration of a network service.

    .DESCRIPTION
        Parse the output of 'networksetup -getinfo' for the given network
        service into an object with the IP address, subnet mask and router.
        Properties are $null if the service is currently not configured.

    .INPUTS
        None.

    .OUTPUTS
        PSCustomObject. IPv4 configuration of the network service.

    .EXAMPLE
        PS /> Get-NetworkServiceInfo -ServiceName 'Wi-Fi'
        Get the IPv4 configuration of the Wi-Fi network service.
#>
function Get-NetworkServiceInfo
{
    [CmdletBinding()]
    param
    (
        # Name of the network service, as shown in System Settings > Network.
        [Parameter(Mandatory = $true)]
        [System.String]
        $ServiceName
    )

    $lines = & networksetup -getinfo $ServiceName

    $serviceInfo = [PSCustomObject] @{
        IPAddress  = $null
        SubnetMask = $null
        Router     = $null
    }

    foreach ($line in $lines)
    {
        if ($line -match '^IP address: (?<Value>.+)$')
        {
            $serviceInfo.IPAddress = $Matches.Value
        }
        elseif ($line -match '^Subnet mask: (?<Value>.+)$')
        {
            $serviceInfo.SubnetMask = $Matches.Value
        }
        elseif ($line -match '^Router: (?<Value>.+)$')
        {
            $serviceInfo.Router = $Matches.Value
        }
    }

    Write-Output $serviceInfo
}
