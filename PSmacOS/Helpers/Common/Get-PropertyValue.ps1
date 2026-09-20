<#
    .SYNOPSIS
        Safely get a property value from an object.

    .DESCRIPTION
        Return the value of the named property, or $null if the object does
        not have that property. Used to read optional properties from
        objects deserialized from JSON (e.g. system_profiler output), where
        not every instance has the same set of properties and Set-StrictMode
        would otherwise throw.

    .INPUTS
        None.

    .OUTPUTS
        System.Object. The property value, or $null.

    .EXAMPLE
        PS /> Get-PropertyValue -InputObject $device -Name 'device_batteryLevel'
        Get the battery level property of the device, or $null if not present.
#>
function Get-PropertyValue
{
    [CmdletBinding()]
    param
    (
        # Object to read the property from.
        [Parameter(Mandatory = $true)]
        [AllowNull()]
        [System.Object]
        $InputObject,

        # Name of the property to read.
        [Parameter(Mandatory = $true)]
        [System.String]
        $Name
    )

    if ($null -ne $InputObject -and $InputObject.PSObject.Properties.Name -contains $Name)
    {
        Write-Output $InputObject.$Name
    }
}
