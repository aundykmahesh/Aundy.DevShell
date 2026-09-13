$script:WorkspaceContextProvider = @{
    Name = 'Workspace'; TimeToLive = [timespan]::FromSeconds(300); RefreshPolicy = 'OnLocationChangeOrExpiry'
    CacheKey = { (Get-Location).Path }; Command = { Get-WorkspaceSnapshot }
    Default = [ordered]@{
        Name = $null; Root = $null; CurrentRepository = $null; Repositories = @(); Solutions = @(); Projects = @()
        GlobalJson = $null; DirectoryBuildProps = $null; DirectoryBuildTargets = $null; DirectoryPackagesProps = $null
        IsWorkspace = $false
    }
}

function Get-WorkspaceAncestors {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string] $Path)

    $directory = Get-Item -LiteralPath $Path -ErrorAction Stop
    if (-not $directory.PSIsContainer) { $directory = $directory.Directory }
    while ($directory) {
        $directory
        $directory = $directory.Parent
    }
}

function Test-WorkspaceMarker {
    [CmdletBinding()]
    param([Parameter(Mandatory)][System.IO.DirectoryInfo] $Directory)

    if (Test-Path -LiteralPath (Join-Path $Directory.FullName '.git')) { return $true }
    foreach ($name in 'global.json','Directory.Build.props','Directory.Build.targets','Directory.Packages.props') {
        if (Test-Path -LiteralPath (Join-Path $Directory.FullName $name) -PathType Leaf) { return $true }
    }
    [bool](Get-ChildItem -LiteralPath $Directory.FullName -File -ErrorAction SilentlyContinue |
        Where-Object Extension -in '.sln','.slnx' | Select-Object -First 1)
}

function Get-WorkspaceSnapshot {
    [CmdletBinding()]
    param([string] $Path = (Get-Location).Path)

    $ancestors = @(Get-WorkspaceAncestors -Path $Path)
    $marked = @($ancestors | Where-Object { Test-WorkspaceMarker -Directory $_ })
    if ($marked.Count -eq 0) {
        return [pscustomobject][ordered]@{
            Name=$null; Root=$null; CurrentRepository=$null; Repositories=@(); Solutions=@(); Projects=@()
            GlobalJson=$null; DirectoryBuildProps=$null; DirectoryBuildTargets=$null; DirectoryPackagesProps=$null
            IsWorkspace=$false
        }
    }

    # The outermost marked ancestor is the workspace; the closest .git ancestor is the active repository.
    $root = $marked[-1]
    $currentRepoRoot = $ancestors | Where-Object { Test-Path -LiteralPath (Join-Path $_.FullName '.git') } | Select-Object -First 1
    $gitMarkers = [System.Collections.Generic.List[System.IO.FileSystemInfo]]::new()
    $solutions = [System.Collections.Generic.List[object]]::new()
    $projects = [System.Collections.Generic.List[object]]::new()
    $workspaceFiles = @{}
    if (Test-Path -LiteralPath (Join-Path $root.FullName '.git')) {
        $gitMarkers.Add((Get-Item -LiteralPath (Join-Path $root.FullName '.git') -Force))
    }

    # Inventory the workspace once. Repeating a recursive walk for every artifact made cold
    # profile startup proportional to the size of the tree several times over.
    foreach ($item in Get-ChildItem -LiteralPath $root.FullName -Force -Recurse -ErrorAction SilentlyContinue) {
        if ($item.Name -eq '.git') { $gitMarkers.Add($item); continue }
        if ($item.PSIsContainer) { continue }
        if ($item.Extension -in '.sln','.slnx') {
            $solutions.Add([pscustomobject][ordered]@{ Name = $item.BaseName; Path = $item.FullName })
        }
        elseif ($item.Extension -eq '.csproj') {
            $projects.Add([pscustomobject][ordered]@{ Name = $item.BaseName; Path = $item.FullName })
        }
        if ($item.Name -in 'global.json','Directory.Build.props','Directory.Build.targets','Directory.Packages.props' -and
            -not $workspaceFiles.ContainsKey($item.Name)) {
            $workspaceFiles[$item.Name] = $item.FullName
        }
    }

    $repositories = @($gitMarkers | ForEach-Object {
        $repoRoot = $_.Parent.FullName
        [pscustomobject][ordered]@{ Name = Split-Path $repoRoot -Leaf; Path = $repoRoot }
    } | Sort-Object Path -Unique)
    $solutions = @($solutions | Sort-Object Path)
    $projects = @($projects | Sort-Object Path)

    [pscustomobject][ordered]@{
        Name = $root.Name
        Root = $root.FullName
        CurrentRepository = if ($currentRepoRoot) { [pscustomobject][ordered]@{ Name=$currentRepoRoot.Name; Path=$currentRepoRoot.FullName } } else { $null }
        Repositories = $repositories
        Solutions = $solutions
        Projects = $projects
        GlobalJson = $workspaceFiles['global.json']
        DirectoryBuildProps = $workspaceFiles['Directory.Build.props']
        DirectoryBuildTargets = $workspaceFiles['Directory.Build.targets']
        DirectoryPackagesProps = $workspaceFiles['Directory.Packages.props']
        IsWorkspace = $true
    }
}

function Get-Workspace {
    <# .SYNOPSIS Discovers the workspace from a path by walking upward to structural markers. #>
    [CmdletBinding()]
    param([string] $Path = (Get-Location).Path, [switch] $Refresh)

    if ($Path -ne (Get-Location).Path) { return ConvertTo-ImmutableDevContextObject (Get-WorkspaceSnapshot -Path $Path) }
    Invoke-DevContextProvider -Registration $script:WorkspaceContextProvider -ForceRefresh:$Refresh
}
