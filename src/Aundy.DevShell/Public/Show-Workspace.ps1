function Show-Workspace {
    [CmdletBinding()]
    param([string] $Path = (Get-Location).Path, [switch] $Refresh)
    $workspace = Get-Workspace -Path $Path -Refresh:$Refresh
    [pscustomobject][ordered]@{
        Name = $workspace.Name; Root = $workspace.Root
        CurrentRepository = $workspace.CurrentRepository.Name
        Repositories = @($workspace.Repositories.Name)
        Solutions = @($workspace.Solutions.Name)
        Projects = @($workspace.Projects.Name)
        RepositoryCount = @($workspace.Repositories).Count
        SolutionCount = @($workspace.Solutions).Count
        ProjectCount = @($workspace.Projects).Count
        Healthy = $workspace.Healthy
    }
}
