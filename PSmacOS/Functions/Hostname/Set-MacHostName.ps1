<#
    .SYNOPSIS
        Set the host name of the local macOS system.

    .DESCRIPTION
        Change the ComputerName (Finder / AirDrop display name), the
        LocalHostName (Bonjour .local name) and the HostName (Unix host name)
        system configuration keys with the scutil command line tool. This
        requires an elevated session, e.g. PowerShell started with sudo.

        If only the Name parameter is given, it is used as is for the
        ComputerName and, sanitized to a valid Bonjour host name (letters,
        digits and hyphens only), for the LocalHostName and HostName as well.
        Use the individual parameters to set the three keys independently.

    .INPUTS
        None.

    .OUTPUTS
        None. Or PSmacOS.HostName if the PassThru switch is used.

    .EXAMPLE
        PS /> Set-MacHostName -Name 'Flavios-MacBook-Pro'
        Set the computer name, local host name and host name to the same,
        sanitized value.

    .EXAMPLE
        PS /> Set-MacHostName -ComputerName "Flavio's MacBook Pro" -LocalHostName 'flavios-macbook-pro' -HostName 'flavios-macbook-pro'
        Set all three host name keys individually.

    .LINK
        https://github.com/flaviowaser/PSmacOS
#>
function Set-MacHostName
{
    [CmdletBinding(SupportsShouldProcess = $true, DefaultParameterSetName = 'Name')]
    param
    (
        # Name used for ComputerName as is, and sanitized for LocalHostName
        # and HostName.
        [Parameter(Mandatory = $true, Position = 0, ParameterSetName = 'Name')]
        [System.String]
        $Name,

        # Finder / AirDrop display name of the system.
        [Parameter(Mandatory = $false, ParameterSetName = 'Individual')]
        [System.String]
        $ComputerName,

        # Bonjour .local name of the system.
        [Parameter(Mandatory = $false, ParameterSetName = 'Individual')]
        [System.String]
        $LocalHostName,

        # Unix host name of the system.
        [Parameter(Mandatory = $false, ParameterSetName = 'Individual')]
        [System.String]
        $HostName,

        # Return the updated host name information.
        [Parameter(Mandatory = $false)]
        [Switch]
        $PassThru
    )

    # Exit if executed on a non-macOS platform
    if ($PSVersionTable.PSVersion.Major -gt 5 -and -not $IsMacOS)
    {
        throw 'This function is only supported on macOS platforms.'
    }

    # Changing the system configuration requires a root session
    Test-AdministratorRole -Throw

    if ($PSCmdlet.ParameterSetName -eq 'Name')
    {
        $ComputerName  = $Name
        $LocalHostName = ConvertTo-BonjourHostName -Name $Name
        $HostName      = ConvertTo-BonjourHostName -Name $Name
    }

    if ($PSCmdlet.ShouldProcess("ComputerName='$ComputerName', LocalHostName='$LocalHostName', HostName='$HostName'", 'Set host name'))
    {
        if ($PSBoundParameters.ContainsKey('ComputerName') -or $PSCmdlet.ParameterSetName -eq 'Name')
        {
            Set-ScutilValue -Key 'ComputerName' -Value $ComputerName
        }

        if ($PSBoundParameters.ContainsKey('LocalHostName') -or $PSCmdlet.ParameterSetName -eq 'Name')
        {
            Set-ScutilValue -Key 'LocalHostName' -Value $LocalHostName
        }

        if ($PSBoundParameters.ContainsKey('HostName') -or $PSCmdlet.ParameterSetName -eq 'Name')
        {
            Set-ScutilValue -Key 'HostName' -Value $HostName
        }

        # Apply the new local host name to the mDNS responder immediately
        & dscacheutil -flushcache
        & killall -HUP mDNSResponder
    }

    if ($PassThru)
    {
        Write-Output (Get-MacHostName)
    }
}
