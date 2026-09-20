

BeforeAll {

    $modulePath = Resolve-Path -Path "$PSScriptRoot\..\..\..\.." | Select-Object -ExpandProperty Path
    $moduleName = Resolve-Path -Path "$PSScriptRoot\..\..\..\.." | Get-Item | Select-Object -ExpandProperty BaseName

    Remove-Module -Name $moduleName -Force -ErrorAction SilentlyContinue
    Import-Module -Name "$modulePath\$moduleName" -Force
}

Describe 'Out-MacGridView' -Skip:($PSVersionTable.PSVersion.Major -gt 5 -and -not $IsMacOS) {

    Context 'No objects piped in' {

        BeforeAll {

            Mock 'osascript' -ModuleName $moduleName { }
        }

        It 'should not call osascript' {

            # Act
            $null | Out-MacGridView

            # Assert
            Should -Invoke 'osascript' -ModuleName $moduleName -Times 0
        }
    }

    Context 'Default (None) parameter set' {

        BeforeAll {

            Mock 'osascript' -ModuleName $moduleName { $Global:LASTEXITCODE = 0; '  1  a  1' }
        }

        It 'should call osascript but not return anything' {

            # Act
            $actual = @('a', 'b') | Out-MacGridView

            # Assert
            $actual | Should -BeNullOrEmpty
            Should -Invoke 'osascript' -ModuleName $moduleName -Times 1
        }
    }

    Context 'PassThru parameter set, first row selected' {

        BeforeAll {

            Mock 'osascript' -ModuleName $moduleName { $Global:LASTEXITCODE = 0; '  1  a' }
        }

        It 'should return the first object even though its index is falsy' {

            # Act
            $actual = @('a', 'b', 'c') | Out-MacGridView -PassThru

            # Assert
            $actual | Should -HaveCount 1
            $actual | Should -Be 'a'
        }
    }

    Context 'PassThru parameter set, multiple rows selected' {

        BeforeAll {

            Mock 'osascript' -ModuleName $moduleName {
                $Global:LASTEXITCODE = 0
                Write-Output '  1  aaa  1'
                Write-Output '  3  ccc  3'
            }
        }

        It 'should return every selected object, in list order' {

            # Act
            $objects = @(
                [PSCustomObject] @{ Name = 'aaa'; Value = 1 }
                [PSCustomObject] @{ Name = 'bbb'; Value = 22 }
                [PSCustomObject] @{ Name = 'ccc'; Value = 3 }
            )
            $actual = $objects | Out-MacGridView -PassThru

            # Assert
            $actual | Should -HaveCount 2
            $actual.Name | Should -Be @('aaa', 'ccc')
        }

        It 'should pass allowMultiple as true to osascript' {

            # Act
            @('a', 'b', 'c') | Out-MacGridView -PassThru | Out-Null

            # Assert
            Should -Invoke 'osascript' -ModuleName $moduleName -Times 1 -ParameterFilter { $args -contains 'true' }
        }
    }

    Context 'OutputMode Single' {

        BeforeAll {

            Mock 'osascript' -ModuleName $moduleName { $Global:LASTEXITCODE = 0; '  2  b' }
        }

        It 'should return only the selected object' {

            # Act
            $actual = @('a', 'b', 'c') | Out-MacGridView -OutputMode Single

            # Assert
            $actual | Should -Be 'b'
        }

        It 'should pass allowMultiple as false to osascript' {

            # Act
            @('a', 'b', 'c') | Out-MacGridView -OutputMode Single | Out-Null

            # Assert
            Should -Invoke 'osascript' -ModuleName $moduleName -Times 1 -ParameterFilter { $args -contains 'false' }
        }
    }

    Context 'Dialog cancelled' {

        BeforeAll {

            Mock 'osascript' -ModuleName $moduleName { $Global:LASTEXITCODE = 0 }
        }

        It 'should not return anything' {

            # Act
            $actual = @('a', 'b') | Out-MacGridView -PassThru

            # Assert
            $actual | Should -BeNullOrEmpty
        }
    }

    Context 'osascript fails' {

        BeforeAll {

            Mock 'osascript' -ModuleName $moduleName { $Global:LASTEXITCODE = 1 }
        }

        It 'should throw an exception' {

            { @('a', 'b') | Out-MacGridView } | Should -Throw
        }
    }
}
