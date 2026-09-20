

BeforeAll {

    $modulePath = Resolve-Path -Path "$PSScriptRoot\..\..\..\.." | Select-Object -ExpandProperty Path
    $moduleName = Resolve-Path -Path "$PSScriptRoot\..\..\.." | Get-Item | Select-Object -ExpandProperty BaseName

    Remove-Module -Name $moduleName -Force -ErrorAction SilentlyContinue
    Import-Module -Name "$modulePath\$moduleName" -Force
}

Describe 'Get-MacHostName' -Skip:($PSVersionTable.PSVersion.Major -gt 5 -and -not $IsMacOS) {

    Context 'All keys set' {

        BeforeAll {

            Mock 'Get-ScutilValue' -ModuleName $moduleName {
                switch ($Key)
                {
                    'ComputerName'  { 'Flavios-MacBook-Pro' }
                    'LocalHostName' { 'flavios-macbook-pro' }
                    'HostName'      { 'flavios-macbook-pro' }
                }
            }
        }

        It 'should return the host name information' {

            # Act
            $actual = Get-MacHostName

            # Assert
            $actual.PSTypeNames | Should -Contain 'PSmacOS.HostName'
            $actual.ComputerName | Should -Be 'Flavios-MacBook-Pro'
            $actual.LocalHostName | Should -Be 'flavios-macbook-pro'
            $actual.HostName | Should -Be 'flavios-macbook-pro'
            $actual.DnsHostName | Should -Not -BeNullOrEmpty
        }
    }

    Context 'HostName key not set' {

        BeforeAll {

            Mock 'Get-ScutilValue' -ModuleName $moduleName {
                switch ($Key)
                {
                    'ComputerName'  { 'Flavios-MacBook-Pro' }
                    'LocalHostName' { 'flavios-macbook-pro' }
                    'HostName'      { $null }
                }
            }
        }

        It 'should return $null for the HostName property' {

            # Act
            $actual = Get-MacHostName

            # Assert
            $actual.HostName | Should -BeNullOrEmpty
        }
    }
}
