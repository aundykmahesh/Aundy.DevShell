BeforeAll {
    Remove-Module Aundy.DevShell -Force -ErrorAction SilentlyContinue
    Import-Module (Join-Path $PSScriptRoot '../src/Aundy.DevShell/Aundy.DevShell.psd1') -Force
}

Describe 'Workspace Engine portable discovery' {
    BeforeEach { InModuleScope Aundy.DevShell { Clear-DevContextCache } }

    It 'returns an empty model outside a workspace' {
        $empty = Join-Path $TestDrive 'empty/deep'
        New-Item -ItemType Directory -Path $empty -Force | Out-Null
        $workspace = Get-Workspace -Path $empty
        $workspace.IsWorkspace | Should -BeFalse
        $workspace.Root | Should -BeNullOrEmpty
        $workspace.Repositories.Count | Should -Be 0
    }

    It 'walks upward from the supplied current directory without assuming a repository container' {
        $root = Join-Path $TestDrive 'portable-root'
        $nested = Join-Path $root 'src/app/deep'
        New-Item -ItemType Directory -Path (Join-Path $root '.git'), $nested -Force | Out-Null
        New-Item -ItemType File -Path (Join-Path $root 'Portable.slnx') -Force | Out-Null
        New-Item -ItemType File -Path (Join-Path $root 'src/app/App.csproj') -Force | Out-Null
        $workspace = Get-Workspace -Path $nested
        $workspace.Root | Should -Be (Get-Item $root).FullName
        $workspace.Name | Should -Be 'portable-root'
        $workspace.CurrentRepository.Name | Should -Be 'portable-root'
        $workspace.Solutions.Name | Should -Contain 'Portable'
        $workspace.Projects.Name | Should -Contain 'App'
        $workspace.Root | Should -Not -Match '^C:\\Git(?:\\|$)'
    }

    It 'discovers nested repositories under a marked parent workspace' {
        $root = Join-Path $TestDrive 'SharedDomain'
        $gateway = Join-Path $root 'Gateway'
        $contracts = Join-Path $root 'Contracts'
        New-Item -ItemType Directory -Path (Join-Path $root '.git'), (Join-Path $gateway '.git'), (Join-Path $contracts '.git') -Force | Out-Null
        $workspace = Get-Workspace -Path $gateway
        $workspace.Name | Should -Be 'SharedDomain'
        $workspace.CurrentRepository.Name | Should -Be 'Gateway'
        $workspace.Repositories.Name | Should -Contain 'Gateway'
        $workspace.Repositories.Name | Should -Contain 'Contracts'
    }

    It 'exposes workspace through DevContext and caches it by location' {
        InModuleScope Aundy.DevShell {
            Mock Get-WorkspaceSnapshot { [pscustomobject]@{ Name='portable'; Root='X:\portable'; IsWorkspace=$true; Repositories=@(); Solutions=@(); Projects=@() } }
            $first = Get-DevContext
            $second = Get-DevContext
            $first.Workspace.Name | Should -Be 'portable'
            $first.Workspace.Cached | Should -BeFalse
            $second.Workspace.Cached | Should -BeTrue
            Should -Invoke Get-WorkspaceSnapshot -Times 1 -Exactly
        }
    }
}
