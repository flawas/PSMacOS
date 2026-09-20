<#
    .SYNOPSIS
        Install macOS software updates on the local system.

    .DESCRIPTION
        Install one or more pending software updates (as reported by the
        softwareupdate command line tool), or all of them at once. This
        requires an elevated session, e.g. PowerShell started with sudo.

        If the Name parameter is omitted, every currently available update is
        installed. Use the Name parameter to install one or more specific
        updates by their label, as returned by the Label property of the
        installed (or would-be-installed) update objects.

    .INPUTS
        System.String. Label of a software update to install, by property
        name.

    .OUTPUTS
        None. Or PSmacOS.SoftwareUpdate if the PassThru switch is used.

    .EXAMPLE
        PS /> Install-MacSoftwareUpdate
        Install all currently available software updates.

    .EXAMPLE
        PS /> Install-MacSoftwareUpdate -Name 'macOSSonomaUpdate-14.5'
        Install a specific software update by its label.

    .EXAMPLE
        PS /> Install-MacSoftwareUpdate -RestartIfNeeded -PassThru
        Install all currently available software updates, restarting the
        system automatically if required, and return the installed updates.

    .LINK
        https://github.com/flaviowaser/PSmacOS
#>
function Install-MacSoftwareUpdate
{
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High', DefaultParameterSetName = 'All')]
    [OutputType('PSmacOS.SoftwareUpdate')]
    param
    (
        # Label of one or more specific updates to install. If omitted, all
        # available updates are installed.
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'Name')]
        [Alias('Label')]
        [System.String[]]
        $Name,

        # Restart the system automatically afterwards, if required by one of
        # the installed updates.
        [Parameter(Mandatory = $false)]
        [Switch]
        $RestartIfNeeded,

        # Return the installed updates.
        [Parameter(Mandatory = $false)]
        [Switch]
        $PassThru
    )

    begin
    {
        # Exit if executed on a non-macOS platform
        if ($PSVersionTable.PSVersion.Major -gt 5 -and -not $IsMacOS)
        {
            throw 'This function is only supported on macOS platforms.'
        }

        # Installing software updates requires a root session
        Test-AdministratorRole -Throw

        $requestedNames = [System.Collections.Generic.List[System.String]]::new()
    }

    process
    {
        if ($PSCmdlet.ParameterSetName -eq 'Name')
        {
            foreach ($updateName in $Name)
            {
                $requestedNames.Add($updateName)
            }
        }
    }

    end
    {
        $availableUpdates = Get-SoftwareUpdateList

        if ($PSCmdlet.ParameterSetName -eq 'Name')
        {
            $updates = $availableUpdates | Where-Object { $_.Label -in $requestedNames }

            foreach ($missingName in ($requestedNames | Where-Object { $_ -notin $availableUpdates.Label }))
            {
                Write-Warning "No available software update found with label '$missingName'."
            }
        }
        else
        {
            $updates = $availableUpdates
        }

        if (-not $updates)
        {
            Write-Verbose 'No software updates are available to install.'
            return
        }

        if ($PSCmdlet.ShouldProcess(($updates.Label -join ', '), 'Install software update'))
        {
            $arguments = @('-i') + $updates.Label

            if ($RestartIfNeeded)
            {
                $arguments += '-R'
            }

            & softwareupdate @arguments

            if ($LASTEXITCODE -ne 0)
            {
                throw "softwareupdate exited with code $LASTEXITCODE while installing: $($updates.Label -join ', ')"
            }
        }

        if ($PassThru)
        {
            Write-Output $updates
        }
    }
}
