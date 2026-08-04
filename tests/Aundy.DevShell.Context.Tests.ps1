BeforeAll {
    $manifestPath = Join-Path $PSScriptRoot '../src/Aundy.DevShell/Aundy.DevShell.psd1'
    Remove-Module Aundy.DevShell -Force -ErrorAction SilentlyContinue
    Import-Module $manifestPath -Force
}

Describe 'Aundy.DevShell mature Context Engine' {
    It 'does not add errors when optional tools are unavailable' {
        InModuleScope Aundy.DevShell {
            Mock Get-Command { $null } -ParameterFilter { $Name -in 'docker','kubectl','az','Get-AzContext','ollama','Get-AIOllamaStatus' }
            Mock Get-Process { $null } -ParameterFilter { $Name -in 'ollama','open-webui','cloudflared' }
            $Error.Clear()
            Get-DockerContext | Out-Null
            Get-KubernetesContext | Out-Null
            Get-AzureContext | Out-Null
            Get-AIContext | Out-Null
            $Error.Count | Should -Be 0
        }
    }
    BeforeEach { InModuleScope Aundy.DevShell { Clear-DevContextCache } }

    It 'returns the nested immutable public contract with provider metadata' {
        $context = Get-DevContext
        $context.PSObject.Properties.Name | Should -Be @('PowerShell', 'Git', 'Azure', 'DotNet', 'Docker', 'Kubernetes', 'AI', 'Machine')
        $context.Git.PSObject.Properties.Name | Should -Contain 'Branch'
        $context.DotNet.PSObject.Properties.Name | Should -Contain 'Sdks'
        foreach ($name in $context.PSObject.Properties.Name) {
            $context.$name.PSObject.Properties.Name | Should -Contain 'Healthy'
            $context.$name.PSObject.Properties.Name | Should -Contain 'ElapsedMilliseconds'
            $context.$name.PSObject.Properties.Name | Should -Contain 'Cached'
            $context.$name.PSObject.Properties.Name | Should -Contain 'LastRefreshUtc'
        }
        { $context.Git.Branch = 'changed' } | Should -Throw
        { $context.Git = $null } | Should -Throw
    }

    It 'keeps providers isolated and caches each independently' {
        InModuleScope Aundy.DevShell {
            Mock Get-GitContext { ConvertTo-ImmutableDevContextObject ([ordered]@{ Repository = 'repo'; Branch = 'cached' }) }
            Mock Get-PowerShellContext { ConvertTo-ImmutableDevContextObject ([ordered]@{ Version = '7.test' }) }
            $first = Get-DevContext
            $second = Get-DevContext
            Should -Invoke Get-GitContext -Times 1 -Exactly
            Should -Invoke Get-PowerShellContext -Times 2 -Exactly
            $first.Git.Cached | Should -BeFalse
            $second.Git.Cached | Should -BeTrue
            $second.Git.CacheHits | Should -Be 1
        }
    }

    It 'refreshes expired and explicitly refreshed provider entries' {
        InModuleScope Aundy.DevShell {
            Mock Get-GitContext { ConvertTo-ImmutableDevContextObject ([ordered]@{ Branch = 'main' }) }
            Get-DevContext | Out-Null
            foreach ($key in @($script:DevContextCache.Keys | Where-Object { $_ -like 'Git:*' })) {
                $script:DevContextCache[$key].LastRefreshUtc = [datetime]::UtcNow.AddMinutes(-1)
            }
            $expired = Get-DevContext
            $forced = Get-DevContext -Refresh
            Should -Invoke Get-GitContext -Times 3 -Exactly
            $expired.Git.Cached | Should -BeFalse
            $forced.Git.Cached | Should -BeFalse
        }
    }

    It 'detects the nearest global.json and inventories SDKs and runtimes' {
        $repo = Join-Path $TestDrive 'repo'
        $nested = Join-Path $repo 'src/app'
        New-Item -ItemType Directory -Path (Join-Path $repo '.git'), $nested -Force | Out-Null
        Set-Content -LiteralPath (Join-Path $repo 'global.json') -Value '{"sdk":{"version":"10.0.100"}}'
        InModuleScope Aundy.DevShell -Parameters @{ Nested = $nested } {
            param($Nested)
            Mock Get-Command { [pscustomobject]@{ Name = 'dotnet' } } -ParameterFilter { $Name -eq 'dotnet' }
            Mock dotnet {
                $global:LASTEXITCODE = 0
                if ($args[0] -eq '--version') { '10.0.101' }
                elseif ($args[0] -eq '--list-sdks') { '9.0.300 [sdk]'; '10.0.101 [sdk]' }
                elseif ($args[0] -eq '--list-runtimes') { 'Microsoft.NETCore.App 9.0.0 [runtime]' }
            }
            Push-Location $Nested
            try { $dotnet = Get-DotNetContext }
            finally { Pop-Location }
            $dotnet.GlobalJsonPresent | Should -BeTrue
            $dotnet.RequiredSdk | Should -Be '10.0.100'
            $dotnet.CurrentSdk | Should -Be '10.0.101'
            $dotnet.SdkCount | Should -Be 2
            $dotnet.RuntimeCount | Should -Be 1
        }
    }

    It 'returns a valid Git provider outside a repository' {
        InModuleScope Aundy.DevShell {
            Mock Get-Command { [pscustomobject]@{ Name = 'git' } } -ParameterFilter { $Name -eq 'git' }
            Mock git { $global:LASTEXITCODE = 128 }
            $git = Get-GitContext
            $git.IsGitRepository | Should -BeFalse
            $git.Repository | Should -BeNullOrEmpty
            { $git.Branch = 'changed' } | Should -Throw
        }
    }

    It 'handles missing Azure CLI, Docker, and Ollama' {
        InModuleScope Aundy.DevShell {
            Mock Get-Command { $null } -ParameterFilter { $Name -in @('Get-AzContext', 'az', 'docker', 'Get-AIOllamaStatus', 'ollama') }
            Mock Get-Process { $null } -ParameterFilter { $Name -in @('ollama', 'open-webui', 'cloudflared') }
            (Get-AzureContext).LoggedIn | Should -BeFalse
            (Get-DockerContext).Running | Should -BeFalse
            $ai = Get-AIContext
            $ai.RuntimeAvailable | Should -BeFalse
            $ai.OllamaRunning | Should -BeFalse
        }
    }

    It 'isolates a provider failure and loads every remaining provider' {
        InModuleScope Aundy.DevShell {
            Mock Get-AzureContext { throw 'Azure failed' }
            Mock Get-GitContext { ConvertTo-ImmutableDevContextObject ([ordered]@{ Branch = 'main'; IsGitRepository = $true }) }
            { $script:context = Get-DevContext } | Should -Not -Throw
            $script:context.Azure.Healthy | Should -BeFalse
            $script:context.Azure.Error | Should -Match 'Azure failed'
            $script:context.Git.Healthy | Should -BeTrue
            $script:context.Git.Branch | Should -Be 'main'
            $script:context.Machine | Should -Not -BeNullOrEmpty
        }
    }

    It 'renders grouped context without executing provider commands itself' {
        $display = Show-DevContext
        $display | Should -Match '(?m)^Machine\r?$'
        $display | Should -Match '(?m)^Git\r?$'
        $display | Should -Match '(?m)^Azure\r?$'
        $display | Should -Match '(?m)^\.NET\r?$'
        $display | Should -Match '(?m)^AI\r?$'
    }

    It 'reports provider health, refresh duration, cache age, and cache hits' {
        $diagnostics = Show-DevShellDiagnostics
        $diagnostics.ProviderHealth.Count | Should -Be 8
        $diagnostics.ProviderHealth[0].PSObject.Properties.Name | Should -Contain 'Healthy'
        $diagnostics.ProviderHealth[0].PSObject.Properties.Name | Should -Contain 'ElapsedMilliseconds'
        $diagnostics.ProviderHealth[0].PSObject.Properties.Name | Should -Contain 'CacheAgeMilliseconds'
        $diagnostics.ProviderHealth[0].PSObject.Properties.Name | Should -Contain 'CacheHits'
        $diagnostics.CacheHits | Should -BeGreaterOrEqual 0
    }
}
