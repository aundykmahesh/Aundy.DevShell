function Invoke-DevWorkflow {
    <#
    .SYNOPSIS Invokes a registered developer workflow.
    .DESCRIPTION Validates and executes a workflow and its dependencies as native processes, returning one structured result.
    .PARAMETER Name Registered workflow name.
    .PARAMETER Parameter Declared workflow parameter values for the requested workflow.
    .PARAMETER Refresh Refreshes workflow and workspace caches before planning.
    .EXAMPLE Invoke-DevWorkflow -Name Test -Parameter @{ Configuration = 'Release' }
    .EXAMPLE Invoke-DevWorkflow -Name Validate -WhatIf
    .OUTPUTS Aundy.DevShell.WorkflowResult
    #>
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact='Medium')]
    param([Parameter(Mandatory)][string] $Name, [hashtable] $Parameter = @{}, [switch] $Refresh)

    $registry = Initialize-DevWorkflowRegistry -Refresh:$Refresh
    $definition = Get-DevWorkflowDefinitionInternal -Name $Name
    $order = Resolve-DevWorkflowDependencyOrder -Definition $definition -Registry $registry
    $steps = [System.Collections.Generic.List[object]]::new()
    $workspace = if (@($order | Where-Object RequiresWorkspace).Count -gt 0) { Get-Workspace -Refresh:$Refresh } else { $null }
    $requestedPlan = New-DevWorkflowPlanInternal -Definition $definition -Parameter $Parameter -Workspace $workspace
    if (-not $requestedPlan.Allowed) { throw ($requestedPlan.Problems -join ' ') }
    if (-not $PSCmdlet.ShouldProcess("workflow '$Name' in '$($requestedPlan.WorkingDirectory)'", "Execute $($requestedPlan.ExecutionOrder -join ' -> ')")) {
        $result = [pscustomobject][ordered]@{ WorkflowName=$Name; Status='Planned'; Succeeded=$false; ExitCode=$null; StartedAt=$null; CompletedAt=$null; DurationMs=0; WorkingDirectory=$requestedPlan.WorkingDirectory; Plan=$requestedPlan; Steps=@(); Output=''; ErrorOutput=''; Error=$null }
        $result.PSObject.TypeNames.Insert(0, 'Aundy.DevShell.WorkflowResult')
        return $result
    }
    $overallStart = [datetime]::UtcNow
    foreach ($stepDefinition in $order) {
        $stepParameters = if ($stepDefinition.Name -ieq $Name) { $Parameter } else { @{} }
        $plan = New-DevWorkflowPlanInternal -Definition $stepDefinition -Parameter $stepParameters -Workspace $workspace
        if (-not $plan.Allowed) {
            $steps.Add([pscustomobject]@{ WorkflowName=$stepDefinition.Name; Status='Blocked'; Succeeded=$false; ExitCode=$null; Error=($plan.Problems -join ' '); Plan=$plan })
            break
        }
        Write-Verbose "Executing workflow step '$($stepDefinition.Name)'."
        $execution = Invoke-DevWorkflowProcess -Plan $plan
        $step = [pscustomobject][ordered]@{ WorkflowName=$stepDefinition.Name; Status=$execution.Status; Succeeded=$execution.Succeeded; ExitCode=$execution.ExitCode; StartedAt=$execution.StartedAt; CompletedAt=$execution.CompletedAt; DurationMs=$execution.DurationMs; Output=$execution.Output; ErrorOutput=$execution.ErrorOutput; Error=$execution.Error; Plan=$plan }
        $step.PSObject.TypeNames.Insert(0, 'Aundy.DevShell.WorkflowStepResult')
        $steps.Add($step)
        if (-not $execution.Succeeded) { break }
    }
    $last = $steps | Select-Object -Last 1
    $succeeded = $steps.Count -eq $order.Count -and @($steps | Where-Object { -not $_.Succeeded }).Count -eq 0
    $result = [pscustomobject][ordered]@{
        WorkflowName=$Name; Status=if ($succeeded) { 'Succeeded' } elseif ($last) { $last.Status } else { 'Blocked' }; Succeeded=$succeeded
        ExitCode=if ($last) { $last.ExitCode } else { $null }; StartedAt=$overallStart; CompletedAt=[datetime]::UtcNow
        DurationMs=[math]::Round(([datetime]::UtcNow - $overallStart).TotalMilliseconds,2); WorkingDirectory=$requestedPlan.WorkingDirectory
        Plan=$requestedPlan; Steps=$steps.ToArray(); Output=if ($last) { $last.Output } else { '' }; ErrorOutput=if ($last) { $last.ErrorOutput } else { '' }; Error=if ($last) { $last.Error } else { 'Workflow was blocked.' }
    }
    $result.PSObject.TypeNames.Insert(0, 'Aundy.DevShell.WorkflowResult')
    $result
}
