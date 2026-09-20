<#
    .SYNOPSIS
        Build script for the PSmacOS PowerShell module.

    .DESCRIPTION
        Analyze and test the module with InvokeBuild. Run interactively with
        'Invoke-Build' for the default 'Build' + 'Test' tasks, or target a
        single task, e.g. 'Invoke-Build -Task Test'.
#>

param
(
    [Parameter(Mandatory = $false)]
    [System.String]
    $ModuleName = 'PSmacOS'
)

$moduleSourcePath = Join-Path -Path $BuildRoot -ChildPath $ModuleName

task Analyze {

    $analyzerResult = Invoke-ScriptAnalyzer -Path $moduleSourcePath -Recurse -Severity Warning,Error

    if ($analyzerResult)
    {
        $analyzerResult | Format-Table -AutoSize | Out-String | Write-Host

        throw 'PSScriptAnalyzer found one or more issues.'
    }
}

task Test {

    $configuration = New-PesterConfiguration
    $configuration.Run.Path = Join-Path -Path $moduleSourcePath -ChildPath 'Tests'
    $configuration.Run.Throw = $true
    $configuration.Output.Verbosity = 'Detailed'

    Invoke-Pester -Configuration $configuration
}

task Build Analyze, Test

task . Build
