BeforeAll {
    Remove-Module Aundy.DevShell -Force -ErrorAction SilentlyContinue
    Import-Module (Join-Path $PSScriptRoot '../src/Aundy.DevShell/Aundy.DevShell.psd1') -Force
    function New-TestDevContext {
        param([bool]$Repo=$true,[bool]$Azure=$true,[bool]$Docker=$true,[bool]$AI=$true)
        [pscustomobject]@{
            PowerShell=[pscustomobject]@{CapturedAt=[datetime]'2026-01-01T21:45:00'}
            Azure=[pscustomobject]@{LoggedIn=$Azure;Subscription='BOQ Group Non-Prod Sub 1'}
            Git=[pscustomobject]@{IsGitRepository=$Repo;Repository='Aundy.DevShell';Branch='main';Dirty=$false;Ahead=0;Behind=0;Conflicted=$false}
            Workspace=[pscustomobject]@{IsWorkspace=$Repo;Name='DeveloperWorkspace'}
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

    It 'composes Git dirty and synchronization state' -ForEach @(
        @{ Dirty=$false; Ahead=0; Behind=0; Expected='✔' }
        @{ Dirty=$true; Ahead=0; Behind=0; Expected='●' }
        @{ Dirty=$false; Ahead=8; Behind=0; Expected='↑8' }
        @{ Dirty=$false; Ahead=0; Behind=2; Expected='↓2' }
        @{ Dirty=$false; Ahead=8; Behind=2; Expected='↑8↓2' }
        @{ Dirty=$true; Ahead=8; Behind=0; Expected='● ↑8' }
        @{ Dirty=$true; Ahead=8; Behind=2; Expected='● ↑8↓2' }
    ) {
        $context=New-TestDevContext
        $context.Git.Dirty=$Dirty; $context.Git.Ahead=$Ahead; $context.Git.Behind=$Behind
        InModuleScope Aundy.DevShell -Parameters @{ context=$context; expected=$Expected } {
            param($context,$expected) $script:PromptStyleOverride='Developer'
            (Get-DevShellPrompt -Context $context).Left.Where({$_.Name -eq 'GitStatus'}).Text | Should -Be $expected
        }
    }

    It 'invalidates only location-sensitive providers when the directory changes' {
        InModuleScope Aundy.DevShell -Parameters @{ context=(New-TestDevContext) } {
            param($context)
            $script:PromptRefreshLocation='C:\one'; $script:PromptRefreshGlobalJsonSignature=''
            Mock Get-Location { [pscustomobject]@{Path='C:\two'} }
            Mock Get-DevShellGlobalJsonSignature { '' }
            Mock Clear-DevContextCache
            Mock Get-DevContext { $context }
            Mock Get-DevShellPrompt { @{Left=@();Right=@();Transient=@();Secondary=@()} }
            Update-DevShellPromptContext | Out-Null
            foreach($provider in 'Git','Workspace','DotNet','Kubernetes') { Should -Invoke Clear-DevContextCache -Times 1 -ParameterFilter { $Provider -eq $provider } }
            Should -Invoke Clear-DevContextCache -Times 0 -Exactly -ParameterFilter { $Provider -in 'Azure','AI','Machine','Docker' }
        }
    }

    It 'invalidates only DotNet when global.json changes in place' {
        InModuleScope Aundy.DevShell -Parameters @{ context=(New-TestDevContext) } {
            param($context)
            $script:PromptRefreshLocation='C:\repo'; $script:PromptRefreshGlobalJsonSignature='old'
            Mock Get-Location { [pscustomobject]@{Path='C:\repo'} }
            Mock Get-DevShellGlobalJsonSignature { 'new' }
            Mock Clear-DevContextCache
            Mock Get-DevContext { $context }
            Mock Get-DevShellPrompt { @{Left=@();Right=@();Transient=@();Secondary=@()} }
            Update-DevShellPromptContext | Out-Null
            Should -Invoke Clear-DevContextCache -Times 1 -Exactly -ParameterFilter { $Provider -eq 'DotNet' }
            Should -Invoke Clear-DevContextCache -Times 1 -Exactly
        }
    }

    It 'renders environment-backed theme slots instead of context literals' {
        InModuleScope Aundy.DevShell -Parameters @{ context=(New-TestDevContext) } {
            param($context) $script:PromptStyleOverride='Developer'
            $theme=Build-Theme -Prompt (Get-DevShellPrompt -Context $context)
            $templates=@($theme.blocks.segments.template)
            $templates | Should -Contain '{{ .Env.AUNDY_PROMPT_GITSTATUS }}'
            ($templates -join '') | Should -Not -Match 'Aundy\.DevShell|BOQ NonProd|Ollama'
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
        $profile = Get-Content (Join-Path $PSScriptRoot '../profile/Microsoft.PowerShell_profile.ps1') -Raw
        $profile | Should -Match 'AundyDevShellPromptHostActivator'
        $profile | Should -Match 'Get-Command -Name oh-my-posh'
        $profile | Should -Match 'init pwsh'
    }

    It 'switches styles without writing the raw model by default' {
        InModuleScope Aundy.DevShell {
            Mock Get-DevContext { [pscustomobject]@{} }
            Mock Get-DevShellPrompt { @{ Style='AI'; Left=@(); Right=@(); Transient=@(); Secondary=@() } }
            Mock New-DevShellPromptTheme { [System.IO.FileInfo]'TestDrive:/Aundy.omp.json' }
            Mock Get-Command { $null }
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

    It 'keeps twenty profile reloads clean and idempotent' {
        InModuleScope Aundy.DevShell {
            $script:PromptStyleOverride='Developer'
            Mock Remove-Module
            Mock Import-Module
            Mock Set-DevShellPromptStyle
            $Error.Clear()
            1..20 | ForEach-Object { Reload-Profile 6>$null }
            $Error.Count | Should -Be 0
            Should -Invoke Remove-Module -Times 0 -Exactly
            Should -Invoke Import-Module -Times 20 -Exactly
            Should -Invoke Set-DevShellPromptStyle -Times 20 -Exactly -ParameterFilter { $Style -eq 'Developer' -and $Restore }
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

    It 'coordinates an unchanged warmed prompt redraw within five milliseconds' {
        InModuleScope Aundy.DevShell -Parameters @{ context=(New-TestDevContext) } {
            param($context)
            $script:PromptRefreshLocation=(Get-Location).Path
            $script:PromptRefreshGlobalJsonSignature=Get-DevShellGlobalJsonSignature -Path $script:PromptRefreshLocation
            $script:PromptRefreshLastContext=$context
            $script:PromptRefreshNextUtc=[datetime]::UtcNow.AddSeconds(30)
            Update-DevShellPromptContext | Out-Null
            $elapsed = 1..5 | ForEach-Object {
                (Measure-Command { 1..50 | ForEach-Object { Update-DevShellPromptContext | Out-Null } }).TotalMilliseconds / 50
            } | Measure-Object -Minimum | Select-Object -ExpandProperty Minimum
            $elapsed | Should -BeLessThan 5
        }
    }

    It 'reports the Oh My Posh CLI product version instead of alias metadata' {
        $diagnostics = Show-DevShellDiagnostics
        if (Get-Command oh-my-posh -ErrorAction Ignore) {
            $diagnostics.OhMyPoshVersion | Should -Match '^\d+\.\d+\.\d+'
            $diagnostics.OhMyPoshVersion | Should -Not -Be '0.0.0.0'
        }
        else { $diagnostics.OhMyPoshVersion | Should -Be 'Unavailable' }
    }
}
