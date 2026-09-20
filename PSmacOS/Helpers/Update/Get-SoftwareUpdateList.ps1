<#
    .SYNOPSIS
        Get the software updates currently available for the local macOS
        system.

    .DESCRIPTION
        Parse the output of the softwareupdate -l command line tool into one
        object per available update, including label, title, version, size,
        whether it is recommended and whether it requires a restart.

    .INPUTS
        None.

    .OUTPUTS
        PSmacOS.SoftwareUpdate. Available software update information.

    .EXAMPLE
        PS /> Get-SoftwareUpdateList
        Get the software updates currently available for the local macOS
        system.
#>
function Get-SoftwareUpdateList
{
    [CmdletBinding()]
    [OutputType('PSmacOS.SoftwareUpdate')]
    param ()

    $output = & softwareupdate -l 2>&1
    $label  = $null

    foreach ($line in $output)
    {
        if ($line -match '^\s*\*\s*Label:\s*(?<Label>.+?)\s*$')
        {
            $label = $Matches.Label
        }
        elseif ($label -and $line -match '^\s*Title:\s*(?<Title>.*?),\s*Version:\s*(?<Version>.*?),\s*Size:\s*(?<Size>.*?),\s*Recommended:\s*(?<Recommended>YES|NO)\s*,?\s*(?:Action:\s*(?<Action>.*?)\s*,?\s*)?$')
        {
            Write-Output ([PSCustomObject] @{
                PSTypeName      = 'PSmacOS.SoftwareUpdate'
                Label           = $label
                Title           = $Matches.Title
                Version         = $Matches.Version
                Size            = $Matches.Size
                Recommended     = $Matches.Recommended -eq 'YES'
                RestartRequired = $Matches.Action -eq 'restart'
            })

            $label = $null
        }
    }
}
