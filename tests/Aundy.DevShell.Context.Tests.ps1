BeforeAll {
    $manifestPath = Join-Path $PSScriptRoot '../src/Aundy.DevShell/Aundy.DevShell.psd1'
    Remove-Module Aundy.DevShell -Force -ErrorAction SilentlyContinue
    Import-Module $manifestPath -Force
}

Describe 'Aundy.DevShell Context Engine' {
    BeforeEach {
        InModuleScope Aundy.DevShell { Clear-DevContextCache }
    }

    It 'composes all provider results into a read-only context' {
        InModuleScope Aundy.DevShell {
            Mock Get-PowerShellContext { [pscustomobject]@{ PowerShellVersion = '7.test'; Administrator = $true; CurrentUser = 'developer' } }
            Mock Get-GitContext { [pscustomobject]@{ Repository = 'C:/repo'; GitBranch = 'main'; GitDirty = $true; GitAhead = 2; GitBehind = 1 } }
            Mock Get-AzureContext { [pscustomobject]@{ AzureSubscription = 'Development'; AzureTenant = 'tenant'; AzureEnvironment = 'AzureCloud' } }
            Mock Get-DotNetContext { [pscustomobject]@{ DotNetVersion = '10.0.100' } }
            Mock Get-DockerContext { [pscustomobject]@{ DockerRunning = $true; KubectlContext = 'local' } }

            $context = Get-DevContext
            $context.PowerShellVersion | Should -Be '7.test'
            $context.GitBranch | Should -Be 'main'
            $context.AzureSubscription | Should -Be 'Development'
            $context.DotNetVersion | Should -Be '10.0.100'
            $context.DockerRunning | Should -BeTrue
            { $context.Add('Unexpected', $true) } | Should -Throw
        }
    }

    It 'uses each provider cache transparently' {
        InModuleScope Aundy.DevShell {
            Mock Get-GitContext { [pscustomobject]@{ Repository = 'C:/repo'; GitBranch = 'cached' } }
            Mock Get-PowerShellContext { [pscustomobject]@{ PowerShellVersion = '7.test' } }

            Get-DevContext | Out-Null
            Get-DevContext | Out-Null

            Should -Invoke Get-GitContext -Times 1 -Exactly
            Should -Invoke Get-PowerShellContext -Times 2 -Exactly
        }
    }

    It 'continues composing context when a provider fails' {
        InModuleScope Aundy.DevShell {
            Mock Get-AzureContext { throw 'Azure failed' }
            Mock Get-DotNetContext { [pscustomobject]@{ DotNetVersion = '10.0.100' } }

            { $script:context = Get-DevContext } | Should -Not -Throw
            $script:context.AzureSubscription | Should -BeNullOrEmpty
            $script:context.DotNetVersion | Should -Be '10.0.100'
            $script:context.ProviderFailures | Should -Match 'Azure failed'
        }
    }

    It 'handles a missing Azure CLI' {
        InModuleScope Aundy.DevShell {
            Mock Get-Command { $null } -ParameterFilter { $Name -in @('Get-AzContext', 'az') }
            $azure = Get-AzureContext
            $azure.AzureSubscription | Should -BeNullOrEmpty
            $azure.AzureTenant | Should -BeNullOrEmpty
        }
    }

    It 'handles missing Docker and kubectl commands' {
        InModuleScope Aundy.DevShell {
            Mock Get-Command { $null } -ParameterFilter { $Name -in @('docker', 'kubectl') }
            $docker = Get-DockerContext
            $docker.DockerRunning | Should -BeFalse
            $docker.KubectlContext | Should -BeNullOrEmpty
        }
    }

    It 'handles execution outside a Git repository' {
        InModuleScope Aundy.DevShell {
            Mock Get-Command { [pscustomobject]@{ Name = 'git' } } -ParameterFilter { $Name -eq 'git' }
            Mock git { $global:LASTEXITCODE = 128 }
            $git = Get-GitContext
            $git.Repository | Should -BeNullOrEmpty
            $git.GitBranch | Should -BeNullOrEmpty
            $git.GitDirty | Should -BeFalse
        }
    }

    It 'builds diagnostics exclusively from the composed context' {
        InModuleScope Aundy.DevShell {
            Mock Get-DevContext {
                [pscustomobject]@{
                    PowerShellVersion = '7.test'; Administrator = $false; CurrentDirectory = 'C:/repo'
                    Repository = 'C:/repo'; GitBranch = 'main'; GitDirty = $false; GitAhead = 0; GitBehind = 0
                    AzureSubscription = 'Development'; AzureEnvironment = 'AzureCloud'; DockerRunning = $false
                    KubectlContext = $null; DotNetVersion = '10.0.100'; AIRuntimeAvailable = $false
                    CurrentUser = 'developer'; ComputerName = 'machine'; OperatingSystem = 'Test OS'; ProviderFailures = @()
                }
            }
            $diagnostics = Show-DevContext
            $diagnostics.Git | Should -Match 'main.*clean'
            $diagnostics.Azure | Should -Match 'Development'
            Should -Invoke Get-DevContext -Times 1 -Exactly
        }
    }
}
