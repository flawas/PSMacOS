

BeforeAll {

    $modulePath = Resolve-Path -Path "$PSScriptRoot\..\..\..\.." | Select-Object -ExpandProperty Path
    $moduleName = Resolve-Path -Path "$PSScriptRoot\..\..\.." | Get-Item | Select-Object -ExpandProperty BaseName

    Remove-Module -Name $moduleName -Force -ErrorAction SilentlyContinue
    Import-Module -Name "$modulePath\$moduleName" -Force
}

Describe 'Get-MacBluetoothDevice' -Skip:($PSVersionTable.PSVersion.Major -gt 5 -and -not $IsMacOS) {

    Context 'One connected, one not connected device' {

        BeforeAll {

            $sampleJson = @'
{
  "SPBluetoothDataType" : [
    {
      "controller_properties" : {
        "controller_address" : "3C:06:30:3A:FF:E2"
      },
      "device_connected" : [
        {
          "Magic Mouse" : {
            "device_address" : "AA:BB:CC:DD:EE:FF",
            "device_batteryLevel" : "75%",
            "device_minorType" : "Mouse",
            "device_vendorID" : "0x004C"
          }
        }
      ],
      "device_not_connected" : [
        {
          "AirPods Pro" : {
            "device_address" : "11:22:33:44:55:66",
            "device_batteryLevelCase" : "24%",
            "device_batteryLevelLeft" : "100%",
            "device_batteryLevelRight" : "100%",
            "device_minorType" : "Headphones",
            "device_vendorID" : "0x004C"
          }
        }
      ]
    }
  ]
}
'@

            Mock 'system_profiler' -ModuleName $moduleName { $sampleJson }
        }

        It 'should return one object per device' {

            # Act
            $actual = @(Get-MacBluetoothDevice)

            # Assert
            $actual.Count | Should -Be 2
        }

        It 'should flag the connected device' {

            # Act
            $actual = Get-MacBluetoothDevice | Where-Object Name -eq 'Magic Mouse'

            # Assert
            $actual.PSTypeNames | Should -Contain 'PSmacOS.BluetoothDevice'
            $actual.Connected | Should -BeTrue
            $actual.Address | Should -Be 'AA:BB:CC:DD:EE:FF'
            $actual.BatteryLevel | Should -Be '75%'
        }

        It 'should flag the not connected device with split battery levels' {

            # Act
            $actual = Get-MacBluetoothDevice | Where-Object Name -eq 'AirPods Pro'

            # Assert
            $actual.Connected | Should -BeFalse
            $actual.BatteryLevelLeft | Should -Be '100%'
            $actual.BatteryLevelRight | Should -Be '100%'
            $actual.BatteryLevelCase | Should -Be '24%'
            $actual.BatteryLevel | Should -BeNullOrEmpty
        }
    }

    Context 'No Bluetooth controller present' {

        BeforeAll {

            Mock 'system_profiler' -ModuleName $moduleName { '{ "SPBluetoothDataType" : [] }' }
        }

        It 'should return no devices' {

            # Act
            $actual = @(Get-MacBluetoothDevice)

            # Assert
            $actual.Count | Should -Be 0
        }
    }
}
