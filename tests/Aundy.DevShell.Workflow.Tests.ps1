BeforeAll {
    Remove-Module Aundy.DevShell -Force -ErrorAction SilentlyContinue
    Import-Module (Join-Path $PSScriptRoot '../src/Aundy.DevShell/Aundy.DevShell.psd1') -Force
}

Describe 'Developer Workflow Engine public contracts' {
    It 'exports the workflow commands' {
        foreach ($name in 'Get-DevWorkflow','Resolve-DevWorkflow','Invoke-DevWorkflow','Test-DevWorkflow') {
            Get-Command $name -Module Aundy.DevShell | Should -Not -BeNullOrEmpty
        }
    }

    It 'returns typed, deterministic built-in definitions' {
        $workflows = Get-DevWorkflow
        $workflows.Name | Should -Be @('Build','Restore','Test','Validate')
        $workflows[0].PSTypeNames | Should -Contain 'Aundy.DevShell.WorkflowDefinition'
        (Get-DevWorkflow -Name build).Name | Should -Be 'Build'
        (Get-DevWorkflow -Category Test).Name | Should -Be 'Test'
        (Get-DevWorkflow -Tag dotnet).Count | Should -Be 4
    }

    It 'rejects unknown workflows' {
        { Get-DevWorkflow -Name Missing -ErrorAction Stop } | Should -Throw "*not registered*"
    }

    It 'reuses and refreshes the lazy registry' {
        InModuleScope Aundy.DevShell {
            $null = Get-DevWorkflow -Refresh
            $created = $script:DevWorkflowRegistryCreatedUtc
            $null = Get-DevWorkflow
            $script:DevWorkflowRegistryCacheHits | Should -BeGreaterThan 0
            $null = Get-DevWorkflow -Refresh
            $script:DevWorkflowRegistryCreatedUtc | Should -BeGreaterOrEqual $created
            $script:DevWorkflowRegistryCacheHits | Should -Be 0
        }
    }
}

Describe 'Developer Workflow planning' {
    BeforeEach {
        InModuleScope Aundy.DevShell {
            Mock Get-Workspace { [pscustomobject]@{ IsWorkspace=$true; Root=$TestDrive } }
            Mock Resolve-DevWorkflowExecutable { 'C:\fixture\dotnet.exe' }
        }
    }

    It 'creates a typed plan without invoking a process' {
        InModuleScope Aundy.DevShell {
            Mock Invoke-DevWorkflowProcess { throw 'must not run' }
            $plan = Resolve-DevWorkflow -Name Build -Parameter @{ Configuration='Release'; NoRestore=$true }
            $plan.PSTypeNames | Should -Contain 'Aundy.DevShell.WorkflowPlan'
            $plan.Allowed | Should -BeTrue
            $plan.ExecutionOrder | Should -Be @('Restore','Build')
            $plan.Arguments | Should -Be @('build','--configuration','Release','--no-restore')
            Should -Invoke Invoke-DevWorkflowProcess -Times 0
            Should -Invoke Get-Workspace -Times 1
        }
    }

    It 'rejects unknown parameters and invalid allowed values' {
        { Resolve-DevWorkflow -Name Build -Parameter @{ Surprise=1 } } | Should -Throw "*does not declare*"
        { Resolve-DevWorkflow -Name Build -Parameter @{ Configuration='Fast' } } | Should -Throw "*must be one of*"
    }

    It 'reports a clean workspace validation problem outside a workspace' {
        InModuleScope Aundy.DevShell {
            Mock Get-Workspace { [pscustomobject]@{ IsWorkspace=$false; Root=$null } }
            $plan = Resolve-DevWorkflow -Name Build
            $plan.Allowed | Should -BeFalse
            $plan.Problems -join ' ' | Should -Match 'requires a workspace'
        }
    }
}

Describe 'Developer Workflow invocation' {
    BeforeEach {
        InModuleScope Aundy.DevShell {
            Mock Get-Workspace { [pscustomobject]@{ IsWorkspace=$true; Root=$TestDrive } }
            Mock Resolve-DevWorkflowExecutable { 'C:\fixture\dotnet.exe' }
        }
    }

    It 'executes dependencies once in deterministic order and returns a structured result' {
        InModuleScope Aundy.DevShell {
            Mock Invoke-DevWorkflowProcess {
                [pscustomobject]@{ Status='Succeeded'; Succeeded=$true; ExitCode=0; StartedAt=[datetime]::UtcNow; CompletedAt=[datetime]::UtcNow; DurationMs=1; Output='ok'; ErrorOutput=''; Error=$null }
            }
            $result = Invoke-DevWorkflow -Name Test -Confirm:$false
            $result.PSTypeNames | Should -Contain 'Aundy.DevShell.WorkflowResult'
            $result.Succeeded | Should -BeTrue
            $result.Steps.WorkflowName | Should -Be @('Restore','Build','Test')
            Should -Invoke Invoke-DevWorkflowProcess -Times 3 -Exactly
        }
    }

    It 'stops after a failed dependency and preserves native failure data' {
        InModuleScope Aundy.DevShell {
            Mock Invoke-DevWorkflowProcess {
                [pscustomobject]@{ Status='Failed'; Succeeded=$false; ExitCode=7; StartedAt=[datetime]::UtcNow; CompletedAt=[datetime]::UtcNow; DurationMs=1; Output=''; ErrorOutput='failed'; Error=$null }
            }
            $result = Invoke-DevWorkflow -Name Test -Confirm:$false
            $result.Status | Should -Be 'Failed'
            $result.ExitCode | Should -Be 7
            $result.Steps.Count | Should -Be 1
        }
    }

    It 'does not start a process under WhatIf' {
        InModuleScope Aundy.DevShell {
            Mock Invoke-DevWorkflowProcess { throw 'must not run' }
            $result = Invoke-DevWorkflow -Name Build -WhatIf
            $result.Status | Should -Be 'Planned'
            $result.Plan.ExecutionOrder | Should -Be @('Restore','Build')
            Should -Invoke Invoke-DevWorkflowProcess -Times 0
        }
    }
}

Describe 'Developer Workflow diagnostics and boundaries' {
    It 'returns read-only structured diagnostics without invoking workflows' {
        InModuleScope Aundy.DevShell {
            Mock Invoke-DevWorkflowProcess { throw 'must not run' }
            Mock Resolve-DevWorkflowExecutable { 'C:\fixture\dotnet.exe' }
            $diagnostic = Test-DevWorkflow -Refresh
            $diagnostic.PSTypeNames | Should -Contain 'Aundy.DevShell.WorkflowDiagnosticResult'
            $diagnostic.Healthy | Should -BeTrue
            $diagnostic.Checks.Name | Should -Contain 'Registry'
            $diagnostic.Checks.Name | Should -Contain 'Cache'
            Should -Invoke Invoke-DevWorkflowProcess -Times 0
        }
    }

    It 'contains no unsafe execution or repository discovery' {
        $engine = Get-Content (Join-Path $PSScriptRoot '../src/Aundy.DevShell/Private/WorkflowEngine.ps1') -Raw
        $engine | Should -Not -Match 'Invoke-Expression|cmd\s+/c'
        $engine | Should -Not -Match 'Get-ChildItem.+-Recurse|\.git'
        $engine | Should -Match 'Get-Workspace'
        $engine | Should -Match 'ArgumentList\.Add'
    }
}
