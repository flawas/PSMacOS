<#
    .SYNOPSIS
        Get the Bluetooth devices paired with the local macOS system.

    .DESCRIPTION
        Return one object per Bluetooth device known to the system, as
        reported by the system_profiler SPBluetoothDataType data type. This
        includes devices that are currently connected as well as paired
        devices that are not connected at the moment.

    .INPUTS
        None.

    .OUTPUTS
        PSmacOS.BluetoothDevice. Bluetooth device information.

    .EXAMPLE
        PS /> Get-MacBluetoothDevice
        Get all known Bluetooth devices.

    .EXAMPLE
        PS /> Get-MacBluetoothDevice | Where-Object Connected
        Get the currently connected Bluetooth devices.

    .LINK
        https://github.com/flaviowaser/PSmacOS
#>
function Get-MacBluetoothDevice
{
    [CmdletBinding()]
    [OutputType('PSmacOS.BluetoothDevice')]
    param ()

    # Exit if executed on a non-macOS platform
    if ($PSVersionTable.PSVersion.Major -gt 5 -and -not $IsMacOS)
    {
        throw 'This function is only supported on macOS platforms.'
    }

    $bluetoothData = (system_profiler SPBluetoothDataType -json | ConvertFrom-Json).SPBluetoothDataType | Select-Object -First 1

    if (-not $bluetoothData)
    {
        return
    }

    # Devices are grouped by the system_profiler tool into a connected and a
    # not connected list, each device represented as an object with a single
    # property named after the device.
    $deviceListProperties = $bluetoothData.PSObject.Properties | Where-Object { $_.Name -like 'device_*connected*' }

    foreach ($deviceListProperty in $deviceListProperties)
    {
        $connected = $deviceListProperty.Name -notmatch 'not_connected'

        foreach ($deviceEntry in @($deviceListProperty.Value))
        {
            foreach ($deviceProperty in $deviceEntry.PSObject.Properties)
            {
                $device = $deviceProperty.Value

                Write-Output ([PSCustomObject] @{
                    PSTypeName         = 'PSmacOS.BluetoothDevice'
                    Name               = $deviceProperty.Name
                    Address            = Get-PropertyValue -InputObject $device -Name 'device_address'
                    Connected          = $connected
                    Type               = Get-PropertyValue -InputObject $device -Name 'device_minorType'
                    VendorID           = Get-PropertyValue -InputObject $device -Name 'device_vendorID'
                    ProductID          = Get-PropertyValue -InputObject $device -Name 'device_productID'
                    FirmwareVersion    = Get-PropertyValue -InputObject $device -Name 'device_firmwareVersion'
                    SerialNumber       = Get-PropertyValue -InputObject $device -Name 'device_serialNumber'
                    BatteryLevel       = Get-PropertyValue -InputObject $device -Name 'device_batteryLevel'
                    BatteryLevelLeft   = Get-PropertyValue -InputObject $device -Name 'device_batteryLevelLeft'
                    BatteryLevelRight  = Get-PropertyValue -InputObject $device -Name 'device_batteryLevelRight'
                    BatteryLevelCase   = Get-PropertyValue -InputObject $device -Name 'device_batteryLevelCase'
                })
            }
        }
    }
}
