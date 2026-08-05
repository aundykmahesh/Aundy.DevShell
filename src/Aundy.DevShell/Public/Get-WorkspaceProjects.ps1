function Get-WorkspaceProjects {
    [CmdletBinding()]
    param([string] $Path = (Get-Location).Path, [switch] $Refresh)
    (Get-Workspace -Path $Path -Refresh:$Refresh).Projects
}
