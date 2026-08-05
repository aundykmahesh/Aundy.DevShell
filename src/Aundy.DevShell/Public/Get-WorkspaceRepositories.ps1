function Get-WorkspaceRepositories {
    [CmdletBinding()]
    param([string] $Path = (Get-Location).Path, [switch] $Refresh)
    (Get-Workspace -Path $Path -Refresh:$Refresh).Repositories
}
