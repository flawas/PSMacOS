<#
    .SYNOPSIS
        Convert a string into a valid Bonjour host name.

    .DESCRIPTION
        Replace every character not allowed in a Bonjour / RFC 1123 host name
        label with a hyphen, collapse repeated hyphens and trim leading and
        trailing hyphens. Used to derive the LocalHostName and HostName from a
        free-form ComputerName.

    .INPUTS
        None.

    .OUTPUTS
        System.String. The sanitized host name.

    .EXAMPLE
        PS /> ConvertTo-BonjourHostName -Name "Flavio's MacBook Pro"
        Convert the name to a valid Bonjour host name.
#>
function ConvertTo-BonjourHostName
{
    [CmdletBinding()]
    [OutputType([System.String])]
    param
    (
        # Free-form name to convert.
        [Parameter(Mandatory = $true)]
        [System.String]
        $Name
    )

    $bonjourHostName = $Name -replace '[^a-zA-Z0-9-]', '-'
    $bonjourHostName = $bonjourHostName -replace '-{2,}', '-'
    $bonjourHostName = $bonjourHostName.Trim('-')

    Write-Output $bonjourHostName
}
