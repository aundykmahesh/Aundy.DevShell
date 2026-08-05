BeforeAll {
    $manifestPath = Join-Path $PSScriptRoot '../src/Aundy.DevShell/Aundy.DevShell.psd1'
    Remove-Module Aundy.DevShell -Force -ErrorAction SilentlyContinue
    Import-Module $manifestPath -Force
}

Describe 'DevShell command discovery' {
    It 'registers every exported command exactly once' {
        $exported = @((Get-Module Aundy.DevShell).ExportedFunctions.Keys | Sort-Object)
        $registered = @(Get-DevShellCommands |
            Where-Object Visibility -eq 'Public' |
            Select-Object -ExpandProperty Name |
            Sort-Object)

        $registered | Should -Be $exported
        ($registered | Group-Object | Where-Object Count -ne 1) | Should -BeNullOrEmpty
    }

    It 'exposes complete command metadata' {
        Get-DevShellCommands | ForEach-Object {
            $_.Name | Should -Not -BeNullOrEmpty
            $_.Category | Should -Not -BeNullOrEmpty
            $_.Summary | Should -Not -BeNullOrEmpty
            ($_.RelatedCommands -is [string[]]) | Should -BeTrue
            $_.Visibility | Should -BeIn @('Public', 'Internal')
        }
    }

    It 'groups registered commands by category in the overview' {
        $output = Show-DevShell | Out-String
        $output | Should -Match 'Aundy\.DevShell v0\.4\.0'
        $output | Should -Match '(?m)^\s*Workspace\s*$'
        $output | Should -Match '(?m)^\s*Get-Workspace\s*$'
        $output | Should -Match '(?m)^\s*Testing\s*$'
    }

    It 'shows a category with command summaries' {
        $output = Show-DevShell workspace | Out-String
        $output | Should -Match '(?m)^\s*Workspace\s*$'
        $output | Should -Match 'Get-Workspace'
        $output | Should -Match 'Returns the current developer workspace\.'
        $output | Should -Not -Match 'Clear-GitWorkspace'
    }

    It 'shows navigation for an exact command' {
        $output = Show-DevShell Get-Workspace | Out-String
        $output | Should -Match '(?m)^\s*Purpose\s*$'
        $output | Should -Match '(?m)^\s*Related\s*$'
        $output | Should -Match 'Get-Help Get-Workspace'
    }

    It 'searches names summaries categories and related commands case insensitively' {
        $output = Show-DevShell cLaUdE | Out-String
        $output | Should -Match 'Invoke-ClaudeLocal'
        $output | Should -Match 'Invoke-ClaudeApi'
    }

    It 'handles an unknown category or command gracefully' {
        $warnings = @()
        $output = Show-DevShell does-not-exist -WarningVariable warnings | Out-String
        $output | Should -BeNullOrEmpty
        $warnings | Out-String | Should -Match 'No DevShell category or command matches'
    }

    It 'provides the dev alias' {
        (Get-Alias dev).Definition | Should -Be 'Show-DevShell'
    }
}
