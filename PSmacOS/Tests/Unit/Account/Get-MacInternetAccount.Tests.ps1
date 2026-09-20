

BeforeAll {

    $modulePath = Resolve-Path -Path "$PSScriptRoot\..\..\..\.." | Select-Object -ExpandProperty Path
    $moduleName = Resolve-Path -Path "$PSScriptRoot\..\..\.." | Get-Item | Select-Object -ExpandProperty BaseName

    Remove-Module -Name $moduleName -Force -ErrorAction SilentlyContinue
    Import-Module -Name "$modulePath\$moduleName" -Force
}

Describe 'Get-MacInternetAccount' -Skip:($PSVersionTable.PSVersion.Major -gt 5 -and -not $IsMacOS) {

    Context 'Database missing' {

        BeforeAll {

            Mock 'Test-Path' -ModuleName $moduleName { $false }
        }

        It 'should throw an exception' {

            { Get-MacInternetAccount } | Should -Throw
        }
    }

    Context 'Full Disk Access not granted' {

        BeforeAll {

            Mock 'Test-Path' -ModuleName $moduleName { $true }
            Mock 'sqlite3' -ModuleName $moduleName { $global:LASTEXITCODE = 1; 'Error: unable to open database "Accounts4.sqlite": authorization denied' }
            Mock 'open' -ModuleName $moduleName { }
        }

        It 'should throw an exception mentioning Full Disk Access' {

            { Get-MacInternetAccount } | Should -Throw '*Full Disk Access*'
        }

        It 'should open the Privacy & Security pane' {

            { Get-MacInternetAccount } | Should -Throw

            Should -Invoke 'open' -ModuleName $moduleName -Times 1
        }
    }

    Context 'Accounts configured' {

        BeforeAll {

            Mock 'Test-Path' -ModuleName $moduleName { $true }
            Mock 'sqlite3' -ModuleName $moduleName {
                $global:LASTEXITCODE = 0
                '[{"AccountType":"iCloud","AccountDescription":"iCloud","UserName":"flavio@icloud.com","OwningBundleID":"com.apple.iCloud"}]'
            }
        }

        It 'should return the configured accounts' {

            # Act
            $actual = @(Get-MacInternetAccount)

            # Assert
            $actual.Count | Should -Be 1
            $actual[0].PSTypeNames | Should -Contain 'PSmacOS.InternetAccount'
            $actual[0].AccountType | Should -Be 'iCloud'
            $actual[0].UserName | Should -Be 'flavio@icloud.com'
        }
    }

    Context 'No accounts configured' {

        BeforeAll {

            Mock 'Test-Path' -ModuleName $moduleName { $true }
            Mock 'sqlite3' -ModuleName $moduleName { $global:LASTEXITCODE = 0 }
        }

        It 'should return no accounts' {

            # Act
            $actual = @(Get-MacInternetAccount)

            # Assert
            $actual.Count | Should -Be 0
        }
    }
}
