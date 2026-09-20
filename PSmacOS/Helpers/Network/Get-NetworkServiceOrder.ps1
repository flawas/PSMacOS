<#
    .SYNOPSIS
        Get the network service order.

    .DESCRIPTION
        Parse the output of 'networksetup -listnetworkserviceorder' into
        objects with the service name, the hardware port, the device and
        whether the service is enabled.

    .INPUTS
        None.

    .OUTPUTS
        PSCustomObject. One object per configured network service.

    .EXAMPLE
        PS /> Get-NetworkServiceOrder
        Get the network service order.
#>
function Get-NetworkServiceOrder
{
    [CmdletBinding()]
    param ()

    $lines = & networksetup -listnetworkserviceorder

    $serviceName = $null
    $enabled     = $true

    foreach ($line in $lines)
    {
        if ($line -match '^\(\d+\)\s+(?<Disabled>\*)?(?<ServiceName>.+)$')
        {
            $serviceName = $Matches.ServiceName
            $enabled     = -not $Matches.ContainsKey('Disabled')
        }
        elseif ($serviceName -and $line -match '^\(Hardware Port: (?<HardwarePort>.+), Device: (?<Device>.*)\)$')
        {
            Write-Output ([PSCustomObject] @{
                ServiceName  = $serviceName
                HardwarePort = $Matches.HardwarePort
                Device       = $Matches.Device
                Enabled      = $enabled
            })

            $serviceName = $null
        }
    }
}
