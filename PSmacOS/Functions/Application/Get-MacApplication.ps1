<#
    .SYNOPSIS
        Get the applications installed on the local macOS system.

    .DESCRIPTION
        Return one object per installed application, as reported by the
        system_profiler SPApplicationsDataType data type. This covers
        applications in /Applications, /System/Applications and other known
        locations, no matter if installed via the Mac App Store, a signed
        installer or manually.

        By default, the macOS default applications that ship with the
        operating system (located in /System/Applications, e.g. Mail, Notes
        or Safari) are excluded, so only applications installed by the user
        are returned. Use the All switch to also include them.

    .INPUTS
        None.

    .OUTPUTS
        PSmacOS.Application. Installed application information.

    .EXAMPLE
        PS /> Get-MacApplication
        Get all applications installed by the user, excluding the macOS
        default applications.

    .EXAMPLE
        PS /> Get-MacApplication -All
        Get all applications, including the macOS default applications.

    .EXAMPLE
        PS /> Get-MacApplication | Where-Object ObtainedFrom -eq 'mac_app_store'
        Get all user-installed applications installed via the Mac App Store.

    .LINK
        https://github.com/flaviowaser/PSmacOS
#>
function Get-MacApplication
{
    [CmdletBinding()]
    [OutputType('PSmacOS.Application')]
    param
    (
        # Also include the macOS default applications shipped with the
        # operating system (located in /System/Applications).
        [Parameter(Mandatory = $false)]
        [Switch]
        $All
    )

    # Exit if executed on a non-macOS platform
    if ($PSVersionTable.PSVersion.Major -gt 5 -and -not $IsMacOS)
    {
        throw 'This function is only supported on macOS platforms.'
    }

    $applications = (system_profiler SPApplicationsDataType -json | ConvertFrom-Json).SPApplicationsDataType

    foreach ($application in $applications)
    {
        $isDefaultApp = $application.path -like '/System/Applications/*'

        if ($isDefaultApp -and -not $All)
        {
            continue
        }

        $signedBy     = Get-PropertyValue -InputObject $application -Name 'signed_by'
        $publisher    = if ($signedBy) { $signedBy[0] } elseif ($application.obtained_from -eq 'apple') { 'Apple Inc.' } else { $null }
        $lastModified = Get-PropertyValue -InputObject $application -Name 'lastModified'

        Write-Output ([PSCustomObject] @{
            PSTypeName    = 'PSmacOS.Application'
            Name          = $application._name
            Version       = Get-PropertyValue -InputObject $application -Name 'version'
            Publisher     = $publisher
            ObtainedFrom  = $application.obtained_from
            Architecture  = (Get-PropertyValue -InputObject $application -Name 'arch_kind') -replace '^arch_', ''
            Path          = $application.path
            Default       = $isDefaultApp
            LastModified  = if ($lastModified) { [System.DateTime] $lastModified } else { $null }
        })
    }
}
