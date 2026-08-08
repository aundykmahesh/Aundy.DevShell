BeforeAll {
    Remove-Module Aundy.DevShell -Force -ErrorAction SilentlyContinue
    Import-Module (Join-Path $PSScriptRoot '../src/Aundy.DevShell/Aundy.DevShell.psd1') -Force
}

Describe 'Configured developer locations' {
    BeforeEach {
        InModuleScope Aundy.DevShell {
            $script:DevLocationRegistry = $null
            $script:DevLocationRegistrySignature = $null
            $script:NavigationFixtureRoot = Join-Path $TestDrive 'profile/source/repos'
            New-Item -ItemType Directory -Path (Join-Path $script:NavigationFixtureRoot 'SharedDomain'), (Join-Path $script:NavigationFixtureRoot 'CBI'), (Join-Path $script:NavigationFixtureRoot 'CE') -Force | Out-Null
            $script:NavigationFixtureSettings = @{
                Navigation = @{ Locations = @(
                    @{ Name='Repos'; Path='%USERPROFILE%\source\repos'; Shortcut='repos'; Enabled=$true }
                    @{ Name='SharedDomain'; Path='SharedDomain'; Parent='Repos'; Shortcut='shared'; Enabled=$true }
                    @{ Name='CBI'; Path='CBI'; Parent='Repos'; Shortcut='cbi'; Enabled=$true }
                    @{ Name='CE'; Path='CE'; Parent='Repos'; Shortcut='ce'; Enabled=$true }
                ) }
            }
            Mock Get-Settings { $script:NavigationFixtureSettings }
            Mock Get-DevLocationSettingsSignature { 'fixture-signature' }
            Mock Expand-DevLocationPath {
                param($Path)
                if ($Path -eq '%USERPROFILE%\source\repos') { return $script:NavigationFixtureRoot }
                $Path
            }
        }
    }

    It 'expands a portable root and resolves parent-relative children' {
        InModuleScope Aundy.DevShell {
            $repos = Get-DevLocation -Name Repos
            $shared = Get-DevLocation -Name SharedDomain
            $repos.Path | Should -Be ([System.IO.Path]::GetFullPath($script:NavigationFixtureRoot))
            $shared.Path | Should -Be ([System.IO.Path]::GetFullPath((Join-Path $script:NavigationFixtureRoot 'SharedDomain')))
            $shared.Parent | Should -Be 'Repos'
        }
    }

    It 'returns structured first-level locations in deterministic order' {
        InModuleScope Aundy.DevShell {
            $locations = Get-DevLocation
            $locations.Name | Should -Be @('CBI','CE','Repos','SharedDomain')
            $locations[0].PSTypeNames | Should -Contain 'Aundy.DevShell.DevLocation'
        }
    }

    It 'matches names case-insensitively' {
        InModuleScope Aundy.DevShell { (Get-DevLocation -Name cBi).Name | Should -Be 'CBI' }
    }

    It 'navigates positionally with a literal path' {
        InModuleScope Aundy.DevShell {
            Mock Test-Path { $true }
            Mock Set-Location {}
            Set-DevLocation CBI
            Should -Invoke Set-Location -Times 1 -Exactly -ParameterFilter { $LiteralPath -eq (Join-Path $script:NavigationFixtureRoot 'CBI') }
        }
    }

    It 'does not navigate under WhatIf' {
        InModuleScope Aundy.DevShell {
            Mock Test-Path { $true }
            Mock Set-Location {}
            Set-DevLocation CBI -WhatIf
            Should -Invoke Set-Location -Times 0
        }
    }

    It 'reports a missing configured folder without changing location' {
        InModuleScope Aundy.DevShell {
            Mock Test-Path { $false }
            Mock Set-Location {}
            { Set-DevLocation CBI } | Should -Throw '*folder does not exist*'
            Should -Invoke Set-Location -Times 0
        }
    }

    It 'rejects an unknown location' {
        InModuleScope Aundy.DevShell { { Get-DevLocation -Name Missing } | Should -Throw '*not configured*' }
    }

    It 'rejects an unknown parent' {
        InModuleScope Aundy.DevShell {
            $settings = @{ Navigation=@{ Locations=@(@{ Name='Child'; Path='child'; Parent='Missing'; Enabled=$true }) } }
            { Initialize-DevLocationRegistry -Settings $settings -Refresh } | Should -Throw '*Unknown parent*'
        }
    }

    It 'rejects circular parents' {
        InModuleScope Aundy.DevShell {
            $settings = @{ Navigation=@{ Locations=@(
                @{ Name='One'; Path='one'; Parent='Two'; Enabled=$true }
                @{ Name='Two'; Path='two'; Parent='One'; Enabled=$true }
            ) } }
            { Initialize-DevLocationRegistry -Settings $settings -Refresh } | Should -Throw '*Circular*'
        }
    }

    It 'rejects duplicate names' {
        InModuleScope Aundy.DevShell {
            $settings = @{ Navigation=@{ Locations=@(
                @{ Name='Same'; Path=$script:NavigationFixtureRoot; Enabled=$true }
                @{ Name='same'; Path=$script:NavigationFixtureRoot; Enabled=$true }
            ) } }
            { Initialize-DevLocationRegistry -Settings $settings -Refresh } | Should -Throw '*Duplicate developer location name*'
        }
    }

    It 'rejects duplicate shortcuts' {
        InModuleScope Aundy.DevShell {
            $settings = @{ Navigation=@{ Locations=@(
                @{ Name='One'; Path=$script:NavigationFixtureRoot; Shortcut='go'; Enabled=$true }
                @{ Name='Two'; Path=$script:NavigationFixtureRoot; Shortcut='GO'; Enabled=$true }
            ) } }
            { Initialize-DevLocationRegistry -Settings $settings -Refresh } | Should -Throw '*Duplicate developer location shortcut*'
        }
    }

    It 'does not return or navigate to disabled locations' {
        InModuleScope Aundy.DevShell {
            $script:NavigationFixtureSettings.Navigation.Locations += @{ Name='Disabled'; Path='Disabled'; Parent='Repos'; Enabled=$false }
            (Get-DevLocation).Name | Should -Not -Contain 'Disabled'
            { Set-DevLocation Disabled } | Should -Throw '*disabled*'
        }
    }

    It 'invalidates cached definitions when configuration changes' {
        InModuleScope Aundy.DevShell {
            $null = Get-DevLocation
            $null = Get-DevLocation
            $script:DevLocationRegistryCacheHits | Should -BeGreaterThan 0
            Mock Get-DevLocationSettingsSignature { 'changed-signature' }
            $null = Get-DevLocation
            $script:DevLocationRegistryCacheHits | Should -Be 0
        }
    }
}

Describe 'Navigation architecture boundaries' {
    It 'uses no recursive discovery, dynamic execution, or machine-specific source path' {
        $engine = Get-Content (Join-Path $PSScriptRoot '../src/Aundy.DevShell/Private/NavigationEngine.ps1') -Raw
        $setter = Get-Content (Join-Path $PSScriptRoot '../src/Aundy.DevShell/Public/Set-DevLocation.ps1') -Raw
        $settings = Get-Content (Join-Path $PSScriptRoot '../src/Aundy.DevShell/Settings.psd1') -Raw
        "$engine`n$setter" | Should -Not -Match 'Invoke-Expression|Get-ChildItem|\s-Recurse\b'
        $setter | Should -Match 'Set-Location\s+-LiteralPath'
        $settings | Should -Not -Match 'C:\\Users\\Mahesh\\source\\repos'
        $settings | Should -Match '%USERPROFILE%\\source\\repos'
    }

    It 'keeps Prompt Engine free of navigation discovery' {
        $prompt = Get-Content (Join-Path $PSScriptRoot '../src/Aundy.DevShell/Prompt/*.ps1') -Raw
        $prompt | Should -Not -Match 'Get-DevLocation|Set-DevLocation|Navigation\.Locations'
    }
}
