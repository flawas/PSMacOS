

BeforeAll {

    $modulePath = Resolve-Path -Path "$PSScriptRoot\..\..\..\.." | Select-Object -ExpandProperty Path
    $moduleName = Resolve-Path -Path "$PSScriptRoot\..\..\..\.." | Get-Item | Select-Object -ExpandProperty BaseName

    Remove-Module -Name $moduleName -Force -ErrorAction SilentlyContinue
    Import-Module -Name "$modulePath\$moduleName" -Force
}

Describe 'Install-MacSoftwareUpdate' -Skip:($PSVersionTable.PSVersion.Major -gt 5 -and -not $IsMacOS) {

    Context 'Not running with root privileges' {

        BeforeAll {

            Mock 'Test-AdministratorRole' -ModuleName $moduleName { throw 'The current session does not have root privileges. Please start PowerShell with sudo.' }
            Mock 'Get-SoftwareUpdateList' -ModuleName $moduleName { }
            Mock 'softwareupdate' -ModuleName $moduleName { }
        }

        It 'should throw an exception' {

            { Install-MacSoftwareUpdate } | Should -Throw
        }

        It 'should not call softwareupdate' {

            { Install-MacSoftwareUpdate } | Should -Throw

            Should -Invoke 'softwareupdate' -ModuleName $moduleName -Times 0
        }
    }

    Context 'No updates available' {

        BeforeAll {

            Mock 'Test-AdministratorRole' -ModuleName $moduleName { }
            Mock 'Get-SoftwareUpdateList' -ModuleName $moduleName { }
            Mock 'softwareupdate' -ModuleName $moduleName { }
        }

        It 'should not call softwareupdate' {

            # Act
            Install-MacSoftwareUpdate -Confirm:$false

            # Assert
            Should -Invoke 'softwareupdate' -ModuleName $moduleName -Times 0
        }

        It 'should not return anything' {

            # Act
            $actual = Install-MacSoftwareUpdate -Confirm:$false

            # Assert
            $actual | Should -BeNullOrEmpty
        }
    }

    Context 'All parameter set' {

        BeforeAll {

            Mock 'Test-AdministratorRole' -ModuleName $moduleName { }
            Mock 'Get-SoftwareUpdateList' -ModuleName $moduleName {
                [PSCustomObject] @{ PSTypeName = 'PSmacOS.SoftwareUpdate'; Label = 'macOSSonomaUpdate-14.5'; Title = 'macOS Sonoma 14.5'; Version = '14.5'; Size = '3182746'; Recommended = $true; RestartRequired = $true }
                [PSCustomObject] @{ PSTypeName = 'PSmacOS.SoftwareUpdate'; Label = 'SafariUpdate-17.5'; Title = 'Safari'; Version = '17.5'; Size = '75000'; Recommended = $true; RestartRequired = $false }
            }
            Mock 'softwareupdate' -ModuleName $moduleName { $Global:LASTEXITCODE = 0 }
        }

        It 'should install all available updates' {

            # Act
            Install-MacSoftwareUpdate -Confirm:$false

            # Assert
            Should -Invoke 'softwareupdate' -ModuleName $moduleName -Times 1 -ParameterFilter {
                $args -contains '-i' -and $args -contains 'macOSSonomaUpdate-14.5' -and $args -contains 'SafariUpdate-17.5' -and $args -notcontains '-R'
            }
        }

        It 'should pass -R when RestartIfNeeded is used' {

            # Act
            Install-MacSoftwareUpdate -RestartIfNeeded -Confirm:$false

            # Assert
            Should -Invoke 'softwareupdate' -ModuleName $moduleName -Times 1 -ParameterFilter { $args -contains '-R' }
        }

        It 'should not return anything without PassThru' {

            # Act
            $actual = Install-MacSoftwareUpdate -Confirm:$false

            # Assert
            $actual | Should -BeNullOrEmpty
        }

        It 'should return the installed updates with PassThru' {

            # Act
            $actual = Install-MacSoftwareUpdate -PassThru -Confirm:$false

            # Assert
            $actual | Should -HaveCount 2
            $actual.Label | Should -Contain 'macOSSonomaUpdate-14.5'
            $actual.Label | Should -Contain 'SafariUpdate-17.5'
        }
    }

    Context 'Name parameter set' {

        BeforeAll {

            Mock 'Test-AdministratorRole' -ModuleName $moduleName { }
            Mock 'Get-SoftwareUpdateList' -ModuleName $moduleName {
                [PSCustomObject] @{ PSTypeName = 'PSmacOS.SoftwareUpdate'; Label = 'macOSSonomaUpdate-14.5'; Title = 'macOS Sonoma 14.5'; Version = '14.5'; Size = '3182746'; Recommended = $true; RestartRequired = $true }
                [PSCustomObject] @{ PSTypeName = 'PSmacOS.SoftwareUpdate'; Label = 'SafariUpdate-17.5'; Title = 'Safari'; Version = '17.5'; Size = '75000'; Recommended = $true; RestartRequired = $false }
            }
            Mock 'softwareupdate' -ModuleName $moduleName { $Global:LASTEXITCODE = 0 }
        }

        It 'should only install the specified update' {

            # Act
            Install-MacSoftwareUpdate -Name 'SafariUpdate-17.5' -Confirm:$false

            # Assert
            Should -Invoke 'softwareupdate' -ModuleName $moduleName -Times 1 -ParameterFilter {
                $args -contains 'SafariUpdate-17.5' -and $args -notcontains 'macOSSonomaUpdate-14.5'
            }
        }

        It 'should warn and not call softwareupdate for an unknown label' {

            # Act
            Install-MacSoftwareUpdate -Name 'DoesNotExist' -Confirm:$false -WarningVariable warnings -WarningAction SilentlyContinue

            # Assert
            $warnings | Should -Not -BeNullOrEmpty
            Should -Invoke 'softwareupdate' -ModuleName $moduleName -Times 0
        }
    }
}
