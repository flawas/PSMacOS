<#
    .SYNOPSIS
        Get network interface information of the local macOS system.

    .DESCRIPTION
        Return one object per configured network service, as shown in
        System Settings > Network, combining the network service order, the
        hardware port and MAC address, and the current IPv4 configuration.
        Wi-Fi services include the currently connected network name (SSID),
        and the service used for the current default route is flagged with
        IsActive.

    .INPUTS
        None.

    .OUTPUTS
        PSmacOS.NetworkInfo. Network interface information.

    .EXAMPLE
        PS /> Get-MacNetworkInfo
        Get the network interface information of the local macOS system.

    .EXAMPLE
        PS /> Get-MacNetworkInfo | Where-Object IsActive
        Get the currently active network interface.

    .LINK
        https://github.com/flaviowaser/PSmacOS
#>
function Get-MacNetworkInfo
{
    [CmdletBinding()]
    [OutputType('PSmacOS.NetworkInfo')]
    param ()

    # Exit if executed on a non-macOS platform
    if ($PSVersionTable.PSVersion.Major -gt 5 -and -not $IsMacOS)
    {
        throw 'This function is only supported on macOS platforms.'
    }

    $hardwarePorts = @(Get-NetworkHardwarePort)
    $primaryDevice = Get-PrimaryNetworkDevice

    foreach ($service in Get-NetworkServiceOrder)
    {
        if ([System.String]::IsNullOrEmpty($service.Device))
        {
            continue
        }

        $hardwarePort = $hardwarePorts | Where-Object { $_.Device -eq $service.Device } | Select-Object -First 1
        $macAddress   = if ($hardwarePort) { $hardwarePort.MACAddress } else { $null }
        $serviceInfo  = Get-NetworkServiceInfo -ServiceName $service.ServiceName

        $ssid = $null
        if ($service.HardwarePort -eq 'Wi-Fi')
        {
            $ssid = Get-WiFiNetworkName -Device $service.Device
        }

        Write-Output ([PSCustomObject] @{
            PSTypeName   = 'PSmacOS.NetworkInfo'
            ServiceName  = $service.ServiceName
            HardwarePort = $service.HardwarePort
            Device       = $service.Device
            Enabled      = $service.Enabled
            MACAddress   = $macAddress
            IPAddress    = $serviceInfo.IPAddress
            SubnetMask   = $serviceInfo.SubnetMask
            Router       = $serviceInfo.Router
            SSID         = $ssid
            IsActive     = ($service.Device -eq $primaryDevice)
        })
    }
}
