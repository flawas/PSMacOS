

BeforeAll {

    $modulePath = Resolve-Path -Path "$PSScriptRoot\..\..\..\.." | Select-Object -ExpandProperty Path
    $moduleName = Resolve-Path -Path "$PSScriptRoot\..\..\.." | Get-Item | Select-Object -ExpandProperty BaseName

    Remove-Module -Name $moduleName -Force -ErrorAction SilentlyContinue
    Import-Module -Name "$modulePath\$moduleName" -Force
}

Describe 'Get-MacApplication' -Skip:($PSVersionTable.PSVersion.Major -gt 5 -and -not $IsMacOS) {

    Context 'Apple, Mac App Store and third party applications' {

        BeforeAll {

            $sampleJson = @'
{
  "SPApplicationsDataType" : [
    {
      "_name" : "Automator",
      "arch_kind" : "arch_arm",
      "lastModified" : "2026-09-03T10:34:10Z",
      "obtained_from" : "apple",
      "path" : "/System/Applications/Automator.app",
      "version" : "2.10"
    },
    {
      "_name" : "Microsoft Edge",
      "arch_kind" : "arch_arm",
      "info" : "Microsoft Edge, some info",
      "lastModified" : "2026-09-10T18:47:47Z",
      "obtained_from" : "identified_developer",
      "path" : "/Applications/Microsoft Edge.app",
      "signed_by" : [
        "Developer ID Application: Microsoft Corporation (UBF8T346G9)",
        "Developer ID Certification Authority",
        "Apple Root CA"
      ],
      "version" : "153.0.4234.32"
    },
    {
      "_name" : "Automator Application Stub",
      "arch_kind" : "arch_arm",
      "lastModified" : "2026-09-03T10:34:10Z",
      "obtained_from" : "unknown",
      "path" : "/System/Library/CoreServices/Automator Application Stub.app",
      "version" : "1.3"
    }
  ]
}
'@

            Mock 'system_profiler' -ModuleName $moduleName { $sampleJson }
        }

        It 'should exclude macOS default applications by default' {

            # Act
            $actual = @(Get-MacApplication)

            # Assert
            $actual.Count | Should -Be 2
            $actual.Name | Should -Not -Contain 'Automator'
        }

        It 'should include macOS default applications with -All' {

            # Act
            $actual = @(Get-MacApplication -All)

            # Assert
            $actual.Count | Should -Be 3
        }

        It 'should set the publisher to Apple Inc. and flag the Default property for Apple applications' {

            # Act
            $actual = Get-MacApplication -All | Where-Object Name -eq 'Automator'

            # Assert
            $actual.PSTypeNames | Should -Contain 'PSmacOS.Application'
            $actual.Publisher | Should -Be 'Apple Inc.'
            $actual.Architecture | Should -Be 'arm'
            $actual.Default | Should -BeTrue
        }

        It 'should not flag applications outside /System/Applications as Default' {

            # Act
            $actual = Get-MacApplication | Where-Object Name -eq 'Microsoft Edge'

            # Assert
            $actual.Default | Should -BeFalse
        }

        It 'should set the publisher from the signed_by certificate chain' {

            # Act
            $actual = Get-MacApplication | Where-Object Name -eq 'Microsoft Edge'

            # Assert
            $actual.Publisher | Should -Be 'Developer ID Application: Microsoft Corporation (UBF8T346G9)'
            $actual.ObtainedFrom | Should -Be 'identified_developer'
        }

        It 'should leave the publisher $null if unknown' {

            # Act
            $actual = Get-MacApplication | Where-Object Name -eq 'Automator Application Stub'

            # Assert
            $actual.Publisher | Should -BeNullOrEmpty
        }
    }
}
