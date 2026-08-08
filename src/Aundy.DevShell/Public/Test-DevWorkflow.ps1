function Test-DevWorkflow {
    <#
    .SYNOPSIS Diagnoses the Developer Workflow Engine.
    .DESCRIPTION Performs read-only registry, definition, dependency, executable, workspace, cache, and public-contract checks. It never invokes workflows.
    .PARAMETER Refresh Rebuilds the registry before diagnosis.
    .EXAMPLE Test-DevWorkflow
    .OUTPUTS Aundy.DevShell.WorkflowDiagnosticResult
    #>
    [CmdletBinding()]
    param([switch] $Refresh)
    $watch = [System.Diagnostics.Stopwatch]::StartNew()
    $checks = [System.Collections.Generic.List[object]]::new()
    try {
        $registry = Initialize-DevWorkflowRegistry -Refresh:$Refresh
        $checks.Add([pscustomobject]@{ Name='Registry'; Healthy=($registry.Count -gt 0); Message="$($registry.Count) workflow(s) registered."; Recommendation=$null })
        foreach ($definition in $registry.Values | Sort-Object Name) {
            $problems = [System.Collections.Generic.List[string]]::new()
            if ([string]::IsNullOrWhiteSpace($definition.Name) -or [string]::IsNullOrWhiteSpace($definition.Command)) { $problems.Add('Name and Command are required.') }
            try { [void](Resolve-DevWorkflowDependencyOrder -Definition $definition -Registry $registry) } catch { $problems.Add($_.Exception.Message) }
            if (-not (Resolve-DevWorkflowExecutable -Command $definition.Command)) { $problems.Add("Executable '$($definition.Command)' is unavailable.") }
            $checks.Add([pscustomobject]@{ Name="Workflow:$($definition.Name)"; Healthy=($problems.Count -eq 0); Message=if ($problems.Count) { $problems -join ' ' } else { 'Definition is valid.' }; Recommendation=if ($problems.Count) { 'Install the required executable or correct the workflow definition.' } else { $null } })
        }
        $publicNames = @('Get-DevWorkflow','Resolve-DevWorkflow','Invoke-DevWorkflow','Test-DevWorkflow')
        $missing = @($publicNames | Where-Object { -not (Get-Command -Name $_ -CommandType Function -ErrorAction SilentlyContinue) })
        $checks.Add([pscustomobject]@{ Name='PublicContracts'; Healthy=($missing.Count -eq 0); Message=if ($missing.Count) { "Missing: $($missing -join ', ')." } else { 'All Workflow Engine public contracts are available.' }; Recommendation=if ($missing.Count) { 'Re-import the module and validate its manifest.' } else { $null } })
        $checks.Add([pscustomobject]@{ Name='Cache'; Healthy=($null -ne $script:DevWorkflowRegistryCreatedUtc); Message="Registry created $script:DevWorkflowRegistryCreatedUtc; cache hits: $script:DevWorkflowRegistryCacheHits."; Recommendation=$null })
    }
    catch { $checks.Add([pscustomobject]@{ Name='Registry'; Healthy=$false; Message=$_.Exception.Message; Recommendation='Refresh the registry and correct invalid built-in definitions.' }) }
    $watch.Stop()
    $result = [pscustomobject][ordered]@{ Engine='Workflow'; Healthy=(@($checks | Where-Object { -not $_.Healthy }).Count -eq 0); Checks=$checks.ToArray(); WorkflowCount=if ($script:DevWorkflowRegistry) { $script:DevWorkflowRegistry.Count } else { 0 }; CacheHits=$script:DevWorkflowRegistryCacheHits; DurationMs=[math]::Round($watch.Elapsed.TotalMilliseconds,2); EngineVersion=$script:DevWorkflowEngineVersion }
    $result.PSObject.TypeNames.Insert(0, 'Aundy.DevShell.WorkflowDiagnosticResult')
    $result
}
