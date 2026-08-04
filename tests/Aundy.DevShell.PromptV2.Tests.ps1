BeforeAll {
    Remove-Module Aundy.DevShell -Force -ErrorAction SilentlyContinue
    Import-Module (Join-Path $PSScriptRoot '../src/Aundy.DevShell/Aundy.DevShell.psd1') -Force
    function New-TestDevContext {
        param([bool]$Repo=$true,[bool]$Azure=$true,[bool]$Docker=$true,[bool]$AI=$true)
        [pscustomobject]@{
            PowerShell=[pscustomobject]@{CapturedAt=[datetime]'2026-01-01T21:45:00'}
            Azure=[pscustomobject]@{LoggedIn=$Azure;Subscription='BOQ Group Non-Prod Sub 1'}
            Git=[pscustomobject]@{IsGitRepository=$Repo;Repository='Aundy.DevShell';Branch='main';Dirty=$false;Ahead=0;Behind=0;Conflicted=$false}
            DotNet=[pscustomobject]@{RequiredSdk='9.0.100';CurrentSdk='10.0.100';GlobalJsonPresent=$true}
            AI=[pscustomobject]@{RuntimeAvailable=$AI;OllamaRunning=$AI;OpenWebUIRunning=$false}
            Docker=[pscustomobject]@{Running=$Docker}
            Kubernetes=[pscustomobject]@{Context='dev'}
            Machine=[pscustomobject]@{Administrator=$false}
        }
    }
}

Describe 'Prompt Engine v2' {
    BeforeEach { InModuleScope Aundy.DevShell { $script:PromptStyleOverride='Minimal' } }

    It 'implements the PromptModel collections and segment contract' {
        $model=Get-DevShellPrompt -Context (New-TestDevContext)
        $model.Keys | Should -Contain 'Transient'
        $model.Keys | Should -Contain 'Secondary'
        foreach($name in 'Name','Enabled','Visible','Order','Priority','Text','Style') { $model.Left[0].Contains($name) | Should -BeTrue }
    }

    It 'supports every built-in style' -ForEach @('Minimal','Developer','Cloud','AI','Presentation') {
        InModuleScope Aundy.DevShell -Parameters @{ style=$_; context=(New-TestDevContext) } {
            param($style,$context) $script:PromptStyleOverride=$style
            (Get-DevShellPrompt -Context $context).Style | Should -Be $style
        }
    }

    It 'uses context-only visibility for unavailable environments' {
        InModuleScope Aundy.DevShell -Parameters @{ context=(New-TestDevContext -Repo:$false -Azure:$false -Docker:$false -AI:$false) } {
            param($context) $script:PromptStyleOverride='Developer'; $m=Get-DevShellPrompt -Context $context
            @($m.Left | Where-Object Name -in Azure,Repository,Branch,GitStatus,Docker,AI | Where-Object Visible).Count | Should -Be 0
        }
    }

    It 'renders all required context values' {
        InModuleScope Aundy.DevShell -Parameters @{ context=(New-TestDevContext) } {
            param($context) $script:PromptStyleOverride='Developer'; $m=Get-DevShellPrompt -Context $context
            ($m.Left|Where-Object Name -eq Time).Text | Should -Be '21:45'
            ($m.Left|Where-Object Name -eq Azure).Text | Should -Be '☁ BOQ NonProd'
            ($m.Left|Where-Object Name -eq DotNet).Text | Should -Be '.NET 9'
            ($m.Left|Where-Object Name -eq AI).Text | Should -Be '🤖 Ollama'
        }
    }

    It 'reports visible and hidden segment names without enumerating dictionary entries' {
        $diagnostics = New-TestDevContext -Azure:$false | Show-DevShellPrompt
        $diagnostics.'Prompt Style' | Should -Be 'Minimal'
        $diagnostics.Visible | Should -Contain 'Time'
        $diagnostics.Hidden | Should -Contain 'Azure'
    }

    It 'keeps process activation outside the Prompt Engine' {
        $promptFiles = Get-ChildItem (Join-Path $PSScriptRoot '../src/Aundy.DevShell/Prompt') -Filter '*.ps1' -Recurse
        $source = $promptFiles | Get-Content -Raw
        $source | Should -Not -Match 'Get-Command\s+-Name\s+oh-my-posh|Invoke-Expression'
        Test-Path (Join-Path $PSScriptRoot '../src/Aundy.DevShell/Public/Set-DevShellPromptStyle.ps1') | Should -BeTrue
    }

    It 'switches styles without writing the raw model by default' {
        InModuleScope Aundy.DevShell {
            Mock Get-DevContext { [pscustomobject]@{} }
            Mock Get-DevShellPrompt { @{ Style='AI'; Left=@(); Right=@(); Transient=@(); Secondary=@() } }
            Mock New-DevShellPromptTheme { [System.IO.FileInfo]'TestDrive:/Aundy.omp.json' }
            Mock Get-Command { $null } -ParameterFilter { $Name -eq 'oh-my-posh' }
            $result = Set-DevShellPromptStyle AI
            $result | Should -BeNullOrEmpty
            $script:PromptStyleOverride | Should -Be 'AI'
            Should -Invoke New-DevShellPromptTheme -Times 1 -Exactly
        }
    }

    It 'preserves and reactivates the active style when reloading' {
        InModuleScope Aundy.DevShell {
            $script:PromptStyleOverride = 'AI'
            Mock Remove-Module
            Mock Import-Module
            Mock Set-DevShellPromptStyle
            Reload-Profile 6>$null
            Should -Invoke Import-Module -Times 1 -Exactly -ParameterFilter { $Global -and $Force -and $DisableNameChecking }
            Should -Invoke Remove-Module -Times 0 -Exactly
            Should -Invoke Set-DevShellPromptStyle -Times 1 -Exactly -ParameterFilter { $Style -eq 'AI' }
        }
    }

    It 'renders valid Oh My Posh JSON and does not rewrite an unchanged theme' {
        $path=Join-Path $TestDrive 'test.omp.json'; $m=Get-DevShellPrompt -Context (New-TestDevContext)
        New-DevShellPromptTheme -Prompt $m -Path $path | Out-Null; $first=(Get-Item $path).LastWriteTimeUtc
        Start-Sleep -Milliseconds 50; New-DevShellPromptTheme -Prompt $m -Path $path | Out-Null
        (Get-Item $path).LastWriteTimeUtc | Should -Be $first
        (Get-Content $path -Raw|ConvertFrom-Json).version | Should -Be 4
    }

    It 'builds a warmed model within five milliseconds' {
        $c=New-TestDevContext; Get-DevShellPrompt -Context $c|Out-Null
        $elapsed = 1..5 | ForEach-Object {
            (Measure-Command { 1..20 | ForEach-Object { Get-DevShellPrompt -Context $c | Out-Null } }).TotalMilliseconds / 20
        } | Measure-Object -Minimum | Select-Object -ExpandProperty Minimum
        $elapsed | Should -BeLessThan 5
    }
}
