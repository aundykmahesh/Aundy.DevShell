BeforeAll {
    $manifestPath = Join-Path $PSScriptRoot '../src/Aundy.DevShell/Aundy.DevShell.psd1'
    Get-Module Aundy.DevShell -All | Remove-Module -Force -ErrorAction SilentlyContinue
    Import-Module $manifestPath -Force
}

Describe 'Test-DevShell' {
    It 'evaluates every registered command exactly once' {
        $registered = @(Get-DevShellCommands)
        $results = @(Test-DevShell)

        $results.Count | Should -Be $registered.Count
        $results.CommandName | Should -Be $registered.Name
    }

    It 'reports healthy registered commands with structured properties' {
        $result = Test-DevShell | Where-Object CommandName -eq 'Get-DevShellCommands'

        $result.Available | Should -BeTrue
        $result.Healthy | Should -BeTrue
        $result.ExpectedCommandType | Should -Be 'Function'
        $result.ActualCommandType | Should -Be 'Function'
        $result.ExpectedModuleName | Should -Be 'Aundy.DevShell'
        $result.ModuleName | Should -Be 'Aundy.DevShell'
        $result.Message | Should -Match 'matches its registered expectations'
    }

    Context 'with controlled registry entries' {
        InModuleScope Aundy.DevShell {
            It 'reports a missing command' {
                Mock Get-DevShellCommands {
                    [pscustomobject]@{ Name = 'Missing-DevShellCommand'; Visibility = 'Public' }
                }
                Mock Get-Command { $null } -ParameterFilter { $Name -eq 'Missing-DevShellCommand' }

                $result = Test-DevShell

                $result.Available | Should -BeFalse
                $result.Healthy | Should -BeFalse
                $result.ActualCommandType | Should -BeNullOrEmpty
                $result.Message | Should -Match 'could not be resolved'
                Should -Invoke Get-Command -Times 1 -Exactly -ParameterFilter { $Name -eq 'Missing-DevShellCommand' }
            }

            It 'reports a wrong command type' {
                Mock Get-DevShellCommands {
                    [pscustomobject]@{
                        Name = 'Wrong-Type'
                        ExpectedCommandType = 'Function'
                        Visibility = 'Public'
                    }
                }
                Mock Get-Command {
                    [pscustomobject]@{ Name = 'Wrong-Type'; CommandType = 'Alias'; ModuleName = 'Aundy.DevShell' }
                }

                $result = Test-DevShell

                $result.Available | Should -BeTrue
                $result.Healthy | Should -BeFalse
                $result.ActualCommandType | Should -Be 'Alias'
                $result.Message | Should -Match "Expected command type 'Function'"
            }

            It 'reports a command resolving from an unrelated module' {
                Mock Get-DevShellCommands {
                    [pscustomobject]@{
                        Name = 'Wrong-Owner'
                        ExpectedCommandType = 'Function'
                        ExpectedModuleName = 'Aundy.DevShell'
                        Visibility = 'Public'
                    }
                }
                Mock Get-Command {
                    [pscustomobject]@{ Name = 'Wrong-Owner'; CommandType = 'Function'; ModuleName = 'Unrelated.Module' }
                }

                $result = Test-DevShell

                $result.Available | Should -BeTrue
                $result.Healthy | Should -BeFalse
                $result.ModuleName | Should -Be 'Unrelated.Module'
                $result.Message | Should -Match "Expected module 'Aundy.DevShell'"
            }

            It 'returns no results for an empty registry' {
                Mock Get-DevShellCommands { @() }
                Mock Get-Command { throw 'Get-Command should not be called for an empty registry.' }

                @(Test-DevShell).Count | Should -Be 0
                Should -Invoke Get-Command -Times 0 -Exactly
            }

            It 'does not include unrelated commands from the session' {
                Mock Get-DevShellCommands {
                    [pscustomobject]@{ Name = 'Only-Registered'; Visibility = 'Public' }
                }
                Mock Get-Command {
                    [pscustomobject]@{ Name = $Name; CommandType = 'Function'; ModuleName = $null }
                }

                $results = @(Test-DevShell)

                $results.CommandName | Should -Be @('Only-Registered')
                $results.CommandName | Should -Not -Contain 'Get-Command'
                $results.CommandName | Should -Not -Contain 'Invoke-Pester'
                Should -Invoke Get-Command -Times 1 -Exactly -ParameterFilter { $Name -eq 'Only-Registered' }
            }
        }
    }
}
