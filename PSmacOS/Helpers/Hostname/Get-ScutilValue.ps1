<#
    .SYNOPSIS
        Get a system configuration value with scutil.

    .DESCRIPTION
        Wrap the macOS scutil command line tool to read one of the system
        configuration host name keys. Return $null if the key is not set.

    .INPUTS
        None.

    .OUTPUTS
        System.String. The value of the requested key, or $null.

    .EXAMPLE
        PS /> Get-ScutilValue -Key 'ComputerName'
        Get the current computer name.
#>
function Get-ScutilValue
{
    [CmdletBinding()]
    [OutputType([System.String])]
    param
    (
        # Name of the system configuration key to read.
        [Parameter(Mandatory = $true)]
        [ValidateSet('ComputerName', 'LocalHostName', 'HostName')]
        [System.String]
        $Key
    )

    $value = & scutil --get $Key 2>$null

    if ($LASTEXITCODE -eq 0)
    {
        Write-Output $value
    }
}
