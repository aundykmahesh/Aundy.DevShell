function Get-DevWorkflow {
    <#
    .SYNOPSIS Lists registered developer workflows.
    .DESCRIPTION Returns structured built-in workflow definitions from the lazy Workflow Engine registry.
    .PARAMETER Name Selects a workflow by exact, case-insensitive name.
    .PARAMETER Category Filters workflows by category.
    .PARAMETER Tag Filters workflows by tag.
    .PARAMETER Refresh Rebuilds the in-memory registry.
    .EXAMPLE Get-DevWorkflow -Name Build
    .OUTPUTS Aundy.DevShell.WorkflowDefinition
    #>
    [CmdletBinding()]
    param([string] $Name, [string] $Category, [string] $Tag, [switch] $Refresh)
    $registry = Initialize-DevWorkflowRegistry -Refresh:$Refresh
    if ($Name) { return Get-DevWorkflowDefinitionInternal -Name $Name }
    @($registry.Values | Where-Object {
        (-not $Category -or $_.Category -ieq $Category) -and (-not $Tag -or $_.Tags -icontains $Tag)
    } | Sort-Object Name)
}
