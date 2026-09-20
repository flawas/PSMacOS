

BeforeAll {

    $modulePath = Resolve-Path -Path "$PSScriptRoot\..\..\..\.." | Select-Object -ExpandProperty Path
    $moduleName = Resolve-Path -Path "$PSScriptRoot\..\..\.." | Get-Item | Select-Object -ExpandProperty BaseName

    Remove-Module -Name $moduleName -Force -ErrorAction SilentlyContinue
    Import-Module -Name "$modulePath\$moduleName" -Force
}

Describe 'Get-MacNetworkInfo' -Skip:($PSVersionTable.PSVersion.Major -gt 5 -and -not $IsMacOS) {

    Context 'Wi-Fi active, Thunderbolt Bridge idle, VPN service without device' {

        BeforeAll {

            Mock 'Get-NetworkServiceOrder' -ModuleName $moduleName {
                [PSCustomObject] @{ ServiceName = 'Wi-Fi'; HardwarePort = 'Wi-Fi'; Device = 'en0'; Enabled = $true }
                [PSCustomObject] @{ ServiceName = 'Thunderbolt Bridge'; HardwarePort = 'Thunderbolt Bridge'; Device = 'bridge0'; Enabled = $true }
                [PSCustomObject] @{ ServiceName = 'UDM-Blauweidweg'; HardwarePort = 'com.ui.uid.standard-desktop'; Device = ''; Enabled = $true }
            }

            Mock 'Get-NetworkHardwarePort' -ModuleName $moduleName {
                [PSCustomObject] @{ HardwarePort = 'Wi-Fi'; Device = 'en0'; MACAddress = '3c:06:30:30:c9:63' }
                [PSCustomObject] @{ HardwarePort = 'Thunderbolt Bridge'; Device = 'bridge0'; MACAddress = '36:0b:61:a6:6f:80' }
            }

            Mock 'Get-NetworkServiceInfo' -ModuleName $moduleName {
                if ($ServiceName -eq 'Wi-Fi')
                {
                    [PSCustomObject] @{ IPAddress = '192.168.0.212'; SubnetMask = '255.255.255.0'; Router = '192.168.0.1' }
                }
                else
                {
                    [PSCustomObject] @{ IPAddress = $null; SubnetMask = $null; Router = $null }
                }
            }

            Mock 'Get-WiFiNetworkName' -ModuleName $moduleName { 'HomeWiFi' }

            Mock 'Get-PrimaryNetworkDevice' -ModuleName $moduleName { 'en0' }
        }

        It 'should skip services without a device' {

            # Act
            $actual = @(Get-MacNetworkInfo)

            # Assert
            $actual.Count | Should -Be 2
        }

        It 'should return the Wi-Fi service as active with its SSID and IPv4 configuration' {

            # Act
            $actual = Get-MacNetworkInfo | Where-Object Device -eq 'en0'

            # Assert
            $actual.PSTypeNames | Should -Contain 'PSmacOS.NetworkInfo'
            $actual.MACAddress | Should -Be '3c:06:30:30:c9:63'
            $actual.IPAddress | Should -Be '192.168.0.212'
            $actual.SSID | Should -Be 'HomeWiFi'
            $actual.IsActive | Should -BeTrue
        }

        It 'should return the Thunderbolt Bridge service as inactive without a SSID' {

            # Act
            $actual = Get-MacNetworkInfo | Where-Object Device -eq 'bridge0'

            # Assert
            $actual.IPAddress | Should -BeNullOrEmpty
            $actual.SSID | Should -BeNullOrEmpty
            $actual.IsActive | Should -BeFalse
        }
    }
}
