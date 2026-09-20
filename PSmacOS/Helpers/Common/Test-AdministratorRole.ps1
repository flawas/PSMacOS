<#
    .SYNOPSIS
        Test if the current session runs with root privileges.

    .DESCRIPTION
        Return $true if the effective user id of the current session is 0
        (root), e.g. because PowerShell was started with sudo. Optionally
        throw an exception if the session is not elevated.

    .INPUTS
        None.

    .OUTPUTS
        System.Boolean. $true if the session is elevated, $false otherwise.

    .EXAMPLE
        PS /> Test-AdministratorRole
        Test if the current session runs with root privileges.

    .EXAMPLE
        PS /> Test-AdministratorRole -Throw
        Throw an exception if the current session does not run with root
        privileges.
#>
function Test-AdministratorRole
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        # Throw an exception instead of returning $false.
        [Parameter(Mandatory = $false)]
        [Switch]
        $Throw
    )

    $isAdministrator = [System.Int32] (id -u) -eq 0

    if ($Throw)
    {
        if (-not $isAdministrator)
        {
            throw 'The current session does not have root privileges. Please start PowerShell with sudo.'
        }
    }
    else
    {
        Write-Output $isAdministrator
    }
}
