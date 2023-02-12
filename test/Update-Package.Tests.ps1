﻿#requires -modules AnyPackage.PowerShellGet

Describe Update-Package {
    BeforeEach {
        Install-PSResource -Name SNMP -Version 1.0 -TrustRepository
        Install-PSResource -Name PSWindowsUpdate -Version 2.0 -TrustRepository
    }

    AfterEach {
        Uninstall-PSResource -Name SNMP, PSWindowsUpdate
    }

    Context 'with no additional parameters' {
        It 'should update' {
            Update-Package -PassThru |
            Should -Not -BeNullOrEmpty
        }
    }

    Context 'with -Name parameter' {
        It 'should update <_>' -TestCases 'SNMP', 'PSWindowsUpdate', @('SNMP', 'PSWindowsUpdate') {
            Update-Package -Name $_ -PassThru |
            Should -HaveCount @($_).Length
        }

        It 'should write error for <_> non-existent package' -TestCases 'doesnotexist' {
            { Update-Package -Name $_ -ErrorAction Stop } |
            Should -Throw -ExpectedMessage "Package not found. (Package '$_')"
        }
    }

    Context 'with -Version parameter' {
        BeforeEach {
            Install-PSResource -Name Cobalt -Version 0.0.1 -TrustRepository
        }

        AfterEach {
            Uninstall-PSResource -Name Cobalt
        }

        It 'should update with <_> version range' -TestCases '0.1.0',
                                                              '[0.1.0]',
                                                              '[0.2.0,]',
                                                              '(0.1.0,)',
                                                              #'(,0.3.0)', https://github.com/PowerShell/PowerShellGet/issues/943
                                                              '(0.2.0,0.3.0]',
                                                              '(0.2.0,0.3.0)',
                                                              '[0.2.0,0.3.0)' {
            Update-Package -Name Cobalt -Version $_ -PassThru |
            Should -Not -BeNullOrEmpty
        }
    }

    Context 'with -Source parameter' {
        BeforeAll {
            $path = Get-PSDrive TestDrive | Select-Object -ExpandProperty Root
            New-Item -Path $path/repo -ItemType Directory
            Register-PSResourceRepository -Name Test -Uri $path/repo -Trusted
            Save-PSResource -Name PSWindowsUpdate, SNMP -Path $path/repo -TrustRepository -AsNupkg
        }

        AfterAll {
            Unregister-PSResourceRepository -Name Test
        }

        It 'should install <Name> from <Source> repository' -TestCases @{ Name = 'SNMP'; Source = 'PSGallery'},
                                                          @{ Name = 'PSWindowsUpdate'; Source = 'Test' } {
            $results = Update-Package -Name $name -Source $source -PassThru
            $results.Source | Should -Be $source
        }
    }

    Context 'with -Prerelease parameter' {
        BeforeAll {
            Install-PSResource -Name Microsoft.PowerShell.Archive -Version 1.0.1 -TrustRepository
        }

        AfterAll {
            Uninstall-PSResource -Name Microsoft.PowerShell.Archive
        }

        It 'should update <_> sucessfully' -TestCases 'Microsoft.PowerShell.Archive' {
            $package = Update-Package -Name $_ -Version '[2.0,2.0.1)' -Prerelease -PassThru

            $package.Version.IsPrerelease | Should -BeTrue
        }
    }

    Context 'with -AcceptLicense parameter' {
        It 'should update <_> successfully' -TestCases 'SNMP' -Skip {
            Update-Package -Name $_ -Provider PowerShellGet -AcceptLicense -PassThru |
            Should -Not -BeNullOrEmpty
        }
    }

    Context 'with -Credential parameter' {
        It 'should update <_> successfully' -TestCases 'SNMP' -Skip {

        }
    }

    Context 'with -TemporaryPath paramter' {
        It 'should update <_> successfully' -TestCases 'SNMP' -Skip {
            Update-Package -Name $_ -Provider PowerShellGet -TemporaryPath TempDrive: -PassThru |
            Should -Not -BeNullOrEmpty
        }
    }

    Context 'with -Scope parameter' {
        It 'should update <_> successfully' -TestCases 'SNMP' -Skip {
            Update-Package -Name $_ -Provider PowerShellGet -Scope CurrentUser -PassThru |
            Should -Not -BeNullOrEmpty
        }
    }

    Context 'with -SkipDependencyCheck' {
        It 'should update <_> successfully' -TestCases 'SNMP' -Skip {
            Update-Package -Name $_ -Provider PowerShellGet -SkipDependencyCheck -PassThru |
            Should -Not -BeNullOrEmpty
        }
    }

    Context 'with pipeline' {
        It 'should update <_> package from Find-Package' -TestCases 'SNMP', @('SNMP', 'PSWindowsUpdate') {
            $results = Find-Package -Name $_ |
            Update-Package -PassThru

            $results | Should -HaveCount @($_).Length
        }

        It 'should Update <_> package from string' -TestCases 'SNMP', @('SNMP', 'PSWindowsUpdate') {
            $results = $_ |
            Update-Package -PassThru

            $results | Should -HaveCount @($_).Length
        }
    }
}
