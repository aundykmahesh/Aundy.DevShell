function Resolve-DevWorkflow {
    <#
    .SYNOPSIS Creates an inspectable developer workflow execution plan.
    .DESCRIPTION Resolves parameters, dependencies, executable, workspace, working directory, and validation problems without execution.
    .PARAMETER Name Registered workflow name.
    .PARAMETER Parameter Declared workflow parameter values.
    .PARAMETER Refresh Refreshes workflow and workspace caches.
    .EXAMPLE Resolve-DevWorkflow -Name Build -Parameter @{ Configuration = 'Release' }
    .OUTPUTS Aundy.DevShell.WorkflowPlan
    #>
    [CmdletBinding()]
    param([Parameter(Mandatory)][string] $Name, [hashtable] $Parameter = @{}, [switch] $Refresh)
    $definition = Get-DevWorkflowDefinitionInternal -Name $Name -Refresh:$Refresh
    New-DevWorkflowPlanInternal -Definition $definition -Parameter $Parameter -Refresh:$Refresh
}
