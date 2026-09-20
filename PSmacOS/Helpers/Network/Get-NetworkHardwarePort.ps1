<#
    .SYNOPSIS
        Get the network hardware ports.

    .DESCRIPTION
        Parse the output of 'networksetup -listallhardwareports' into
        objects with the hardware port name, the device and the MAC address.

    .INPUTS
        None.

    .OUTPUTS
        PSCustomObject. One object per network hardware port.

    .EXAMPLE
        PS /> Get-NetworkHardwarePort
        Get the network hardware ports.
#>
function Get-NetworkHardwarePort
{
    [CmdletBinding()]
    param ()

    $lines = @(& networksetup -listallhardwareports) + ''

    $hardwarePort = $null
    $device       = $null
    $macAddress   = $null

    foreach ($line in $lines)
    {
        if ($line -match '^Hardware Port: (?<Value>.+)$')
        {
            $hardwarePort = $Matches.Value
        }
        elseif ($line -match '^Device: (?<Value>.+)$')
        {
            $device = $Matches.Value
        }
        elseif ($line -match '^Ethernet Address: (?<Value>.+)$')
        {
            $macAddress = $Matches.Value
        }
        elseif ([System.String]::IsNullOrWhiteSpace($line))
        {
            if ($hardwarePort -and $device)
            {
                Write-Output ([PSCustomObject] @{
                    HardwarePort = $hardwarePort
                    Device       = $device
                    MACAddress   = $macAddress
                })
            }

            $hardwarePort = $null
            $device       = $null
            $macAddress   = $null
        }
    }
}
