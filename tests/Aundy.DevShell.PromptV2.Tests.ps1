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

    It 'renders valid Oh My Posh JSON and does not rewrite an unchanged theme' {
        $path=Join-Path $TestDrive 'test.omp.json'; $m=Get-DevShellPrompt -Context (New-TestDevContext)
        New-DevShellPromptTheme -Prompt $m -Path $path | Out-Null; $first=(Get-Item $path).LastWriteTimeUtc
        Start-Sleep -Milliseconds 50; New-DevShellPromptTheme -Prompt $m -Path $path | Out-Null
        (Get-Item $path).LastWriteTimeUtc | Should -Be $first
        (Get-Content $path -Raw|ConvertFrom-Json).version | Should -Be 4
    }

    It 'builds a warmed model within five milliseconds' {
        $c=New-TestDevContext; Get-DevShellPrompt -Context $c|Out-Null
        $elapsed=(Measure-Command { 1..20|ForEach-Object { Get-DevShellPrompt -Context $c|Out-Null } }).TotalMilliseconds/20
        $elapsed | Should -BeLessThan 5
    }
}
