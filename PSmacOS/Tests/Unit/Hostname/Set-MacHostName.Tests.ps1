

BeforeAll {

    $modulePath = Resolve-Path -Path "$PSScriptRoot\..\..\..\.." | Select-Object -ExpandProperty Path
    $moduleName = Resolve-Path -Path "$PSScriptRoot\..\..\.." | Get-Item | Select-Object -ExpandProperty BaseName

    Remove-Module -Name $moduleName -Force -ErrorAction SilentlyContinue
    Import-Module -Name "$modulePath\$moduleName" -Force
}

Describe 'Set-MacHostName' -Skip:($PSVersionTable.PSVersion.Major -gt 5 -and -not $IsMacOS) {

    Context 'Not running with root privileges' {

        BeforeAll {

            Mock 'Test-AdministratorRole' -ModuleName $moduleName { throw 'The current session does not have root privileges. Please start PowerShell with sudo.' }
            Mock 'Set-ScutilValue' -ModuleName $moduleName { }
        }

        It 'should throw an exception' {

            { Set-MacHostName -Name 'Flavios-MacBook-Pro' } | Should -Throw
        }

        It 'should not call Set-ScutilValue' {

            { Set-MacHostName -Name 'Flavios-MacBook-Pro' } | Should -Throw

            Should -Invoke 'Set-ScutilValue' -ModuleName $moduleName -Times 0
        }
    }

    Context 'Name parameter set' {

        BeforeAll {

            Mock 'Test-AdministratorRole' -ModuleName $moduleName { }
            Mock 'Set-ScutilValue' -ModuleName $moduleName { }
            Mock 'Get-MacHostName' -ModuleName $moduleName { }
            Mock 'dscacheutil' -ModuleName $moduleName { }
            Mock 'killall' -ModuleName $moduleName { }
        }

        It 'should set all three keys with a sanitized local and host name' {

            # Act
            Set-MacHostName -Name "Flavio's MacBook Pro" -Confirm:$false

            # Assert
            Should -Invoke 'Set-ScutilValue' -ModuleName $moduleName -Times 1 -ParameterFilter { $Key -eq 'ComputerName' -and $Value -eq "Flavio's MacBook Pro" }
            Should -Invoke 'Set-ScutilValue' -ModuleName $moduleName -Times 1 -ParameterFilter { $Key -eq 'LocalHostName' -and $Value -eq 'Flavio-s-MacBook-Pro' }
            Should -Invoke 'Set-ScutilValue' -ModuleName $moduleName -Times 1 -ParameterFilter { $Key -eq 'HostName' -and $Value -eq 'Flavio-s-MacBook-Pro' }
        }

        It 'should not return anything without PassThru' {

            # Act
            $actual = Set-MacHostName -Name 'Flavios-MacBook-Pro' -Confirm:$false

            # Assert
            $actual | Should -BeNullOrEmpty
        }
    }

    Context 'Individual parameter set' {

        BeforeAll {

            Mock 'Test-AdministratorRole' -ModuleName $moduleName { }
            Mock 'Set-ScutilValue' -ModuleName $moduleName { }
            Mock 'dscacheutil' -ModuleName $moduleName { }
            Mock 'killall' -ModuleName $moduleName { }
        }

        It 'should only set the specified key' {

            # Act
            Set-MacHostName -HostName 'flavios-macbook-pro' -Confirm:$false

            # Assert
            Should -Invoke 'Set-ScutilValue' -ModuleName $moduleName -Times 1 -ParameterFilter { $Key -eq 'HostName' -and $Value -eq 'flavios-macbook-pro' }
            Should -Invoke 'Set-ScutilValue' -ModuleName $moduleName -Times 0 -ParameterFilter { $Key -eq 'ComputerName' }
            Should -Invoke 'Set-ScutilValue' -ModuleName $moduleName -Times 0 -ParameterFilter { $Key -eq 'LocalHostName' }
        }
    }
}
