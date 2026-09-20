<#
    .SYNOPSIS
        Send pipeline output to an interactive, searchable list window.

    .DESCRIPTION
        Display the piped objects as a table in a native macOS "choose from
        list" window (which lets the user type to filter the rows), similar
        in spirit to the Windows PowerShell Out-GridView cmdlet. The command
        always waits for the window to be closed before returning, since the
        underlying macOS dialog is modal.

        By default, nothing is written back to the pipeline; the window is
        purely informational. Use PassThru, or OutputMode Single or
        Multiple, to have the row(s) selected by the user written back to
        the pipeline.

    .INPUTS
        System.Object. Objects to display in the grid view.

    .OUTPUTS
        System.Object. The object(s) selected by the user, if PassThru or
        OutputMode Single/Multiple is used. Otherwise none.

    .EXAMPLE
        PS /> Get-MacApplication | Out-MacGridView
        Display the installed applications in a searchable list window.

    .EXAMPLE
        PS /> Get-MacBluetoothDevice | Out-MacGridView -Title 'Bluetooth Devices' -PassThru
        Display the paired Bluetooth devices and return the one(s) selected
        by the user.

    .EXAMPLE
        PS /> Get-MacInternetAccount | Out-MacGridView -OutputMode Single
        Display the configured internet accounts and return at most the one
        selected by the user.

    .LINK
        https://github.com/flaviowaser/PSmacOS
#>
function Out-MacGridView
{
    [CmdletBinding(DefaultParameterSetName = 'None')]
    param
    (
        # Objects to display in the grid view.
        [Parameter(Mandatory = $false, ValueFromPipeline = $true)]
        [AllowNull()]
        [System.Object]
        $InputObject,

        # Text shown in the title of the grid view window.
        [Parameter(Mandatory = $false)]
        [System.String]
        $Title = 'Out-MacGridView',

        # Items the window sends back to the pipeline: None (default), a
        # Single item or Multiple items.
        [Parameter(Mandatory = $true, ParameterSetName = 'OutputMode')]
        [ValidateSet('None', 'Single', 'Multiple')]
        [System.String]
        $OutputMode,

        # Send every item selected by the user back to the pipeline.
        # Equivalent to OutputMode Multiple.
        [Parameter(Mandatory = $false, ParameterSetName = 'PassThru')]
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

        $objects = [System.Collections.Generic.List[System.Object]]::new()
    }

    process
    {
        if ($null -ne $InputObject)
        {
            $objects.Add($InputObject)
        }
    }

    end
    {
        if ($objects.Count -eq 0)
        {
            Write-Verbose 'No objects to display.'
            return
        }

        $allowMultiple = $PassThru -or $OutputMode -eq 'Multiple'

        # Objects with no properties of their own (e.g. plain strings or
        # numbers) are displayed as a single Value column instead.
        $isSimpleValue = $objects[0] -is [System.String] -or $objects[0] -is [System.ValueType]
        $properties    = if ($isSimpleValue) { @('Value') } else { $objects[0].PSObject.Properties.Name }

        $resolveValue = {
            param ($RowObject, $Property)

            if ($isSimpleValue) { $RowObject } else { Get-PropertyValue -InputObject $RowObject -Name $Property }
        }

        $columnWidths = [Ordered] @{}
        foreach ($property in $properties)
        {
            $valueWidth = ($objects | ForEach-Object { "$(& $resolveValue $_ $property)".Length } | Measure-Object -Maximum).Maximum
            $columnWidths[$property] = [Math]::Max($property.Length, $valueWidth)
        }

        $indexWidth = "$($objects.Count)".Length
        $headerLine = (' ' * $indexWidth) + '  ' + (($properties | ForEach-Object { $_.PadRight($columnWidths[$_]) }) -join '  ')

        $rowLines = for ($i = 0; $i -lt $objects.Count; $i++)
        {
            $rowValues = $properties | ForEach-Object { "$(& $resolveValue $objects[$i] $_)".PadRight($columnWidths[$_]) }
            '{0}  {1}' -f "$($i + 1)".PadLeft($indexWidth), ($rowValues -join '  ')
        }

        $appleScript = @'
on run argv
    set theTitle to item 1 of argv
    set thePrompt to item 2 of argv
    set allowMultiple to (item 3 of argv) is "true"
    set theItems to items 4 thru (count of argv) of argv

    set chosenItems to choose from list theItems with title theTitle with prompt thePrompt multiple selections allowed allowMultiple

    if chosenItems is false then
        return ""
    end if

    set {savedDelimiters, AppleScript's text item delimiters} to {AppleScript's text item delimiters, linefeed}
    set theResult to chosenItems as text
    set AppleScript's text item delimiters to savedDelimiters

    return theResult
end run
'@

        $scriptPath = Join-Path -Path ([System.IO.Path]::GetTempPath()) -ChildPath "$([System.Guid]::NewGuid()).applescript"

        try
        {
            Set-Content -Path $scriptPath -Value $appleScript -NoNewline

            $arguments      = @($Title, $headerLine, $(if ($allowMultiple) { 'true' } else { 'false' })) + $rowLines
            $selectionLines = & osascript $scriptPath @arguments

            if ($LASTEXITCODE -ne 0)
            {
                throw "osascript exited with code $LASTEXITCODE while displaying the grid view."
            }
        }
        finally
        {
            Remove-Item -Path $scriptPath -Force -ErrorAction SilentlyContinue
        }

        if (-not ($PassThru -or $OutputMode -in @('Single', 'Multiple')))
        {
            return
        }

        $selectedIndexes = @(
            foreach ($line in $selectionLines)
            {
                if ($line -match '^\s*(?<Index>\d+)\s')
                {
                    ([System.Int32] $Matches.Index) - 1
                }
            }
        )

        if ($selectedIndexes.Count -eq 0)
        {
            return
        }

        if ($OutputMode -eq 'Single')
        {
            Write-Output $objects[$selectedIndexes[0]]
        }
        else
        {
            foreach ($index in $selectedIndexes)
            {
                Write-Output $objects[$index]
            }
        }
    }
}
