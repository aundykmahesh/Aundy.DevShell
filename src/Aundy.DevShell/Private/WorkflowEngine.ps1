$script:DevWorkflowRegistry = $null
$script:DevWorkflowRegistryCreatedUtc = $null
$script:DevWorkflowRegistryCacheHits = 0
$script:DevWorkflowEngineVersion = '1.0'
$script:DevWorkflowOutputLimit = 1048576

function New-DevWorkflowDefinition {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string] $Name,
        [Parameter(Mandatory)][string] $DisplayName,
        [Parameter(Mandatory)][string] $Description,
        [Parameter(Mandatory)][string] $Category,
        [Parameter(Mandatory)][string] $Command,
        [string[]] $Arguments = @(),
        [object[]] $Parameters = @(),
        [string[]] $DependsOn = @(),
        [string[]] $Tags = @(),
        [int] $TimeoutSeconds = 900,
        [bool] $RequiresWorkspace = $false
    )

    $definition = [pscustomobject][ordered]@{
        Name = $Name; DisplayName = $DisplayName; Description = $Description; Category = $Category
        Command = $Command; Arguments = @($Arguments); WorkingDirectory = if ($RequiresWorkspace) { 'WorkspaceRoot' } else { 'CurrentDirectory' }
        Parameters = @($Parameters); Prerequisites = @('Executable'); DependsOn = @($DependsOn)
        Environment = [ordered]@{}; TimeoutSeconds = $TimeoutSeconds; ContinueOnError = $false
        SupportsWhatIf = $true; Tags = @($Tags); Source = 'BuiltIn'; Version = '1.0'
        Enabled = $true; RequiresWorkspace = $RequiresWorkspace; Metadata = [ordered]@{}
    }
    $definition.PSObject.TypeNames.Insert(0, 'Aundy.DevShell.WorkflowDefinition')
    $definition
}

function New-DevWorkflowParameterDefinition {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string] $Name,
        [ValidateSet('String','Switch')][string] $Type = 'String',
        [bool] $Required = $false,
        [AllowNull()] $DefaultValue,
        [string[]] $AllowedValues = @(),
        [Parameter(Mandatory)][string] $Argument,
        [bool] $Sensitive = $false
    )
    [pscustomobject][ordered]@{
        Name=$Name; Type=$Type; Required=$Required; DefaultValue=$DefaultValue
        AllowedValues=@($AllowedValues); Argument=$Argument; Sensitive=$Sensitive
    }
}

function Initialize-DevWorkflowRegistry {
    [CmdletBinding()]
    param([switch] $Refresh)

    if ($script:DevWorkflowRegistry -and -not $Refresh) {
        $script:DevWorkflowRegistryCacheHits++
        return $script:DevWorkflowRegistry
    }

    $configuration = New-DevWorkflowParameterDefinition -Name Configuration -DefaultValue 'Debug' -AllowedValues @('Debug','Release') -Argument '--configuration'
    $noRestore = New-DevWorkflowParameterDefinition -Name NoRestore -Type Switch -DefaultValue $false -Argument '--no-restore'
    $registry = [ordered]@{}
    $definitions = @(
        New-DevWorkflowDefinition -Name Restore -DisplayName 'Restore workspace' -Description 'Restores dependencies for the current workspace.' -Category Build -Command dotnet -Arguments @('restore') -Tags @('dotnet','restore') -RequiresWorkspace $true
        New-DevWorkflowDefinition -Name Build -DisplayName 'Build workspace' -Description 'Builds the current workspace.' -Category Build -Command dotnet -Arguments @('build') -Parameters @($configuration,$noRestore) -DependsOn @('Restore') -Tags @('dotnet','build') -RequiresWorkspace $true
        New-DevWorkflowDefinition -Name Test -DisplayName 'Test workspace' -Description 'Runs tests for the current workspace.' -Category Test -Command dotnet -Arguments @('test') -Parameters @($configuration,$noRestore) -DependsOn @('Build') -Tags @('dotnet','test') -RequiresWorkspace $true
        New-DevWorkflowDefinition -Name Validate -DisplayName 'Validate workspace' -Description 'Restores, builds, and tests the current workspace.' -Category Validation -Command dotnet -Arguments @('test','--no-build') -Parameters @($configuration) -DependsOn @('Test') -Tags @('dotnet','validation') -RequiresWorkspace $true
    )
    foreach ($definition in $definitions) {
        if ($registry.Contains($definition.Name)) { throw "Duplicate workflow name '$($definition.Name)'." }
        $registry[$definition.Name] = $definition
    }
    $script:DevWorkflowRegistry = $registry
    $script:DevWorkflowRegistryCreatedUtc = [datetime]::UtcNow
    $script:DevWorkflowRegistryCacheHits = 0
    $registry
}

function Get-DevWorkflowDefinitionInternal {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string] $Name, [switch] $Refresh)
    $registry = Initialize-DevWorkflowRegistry -Refresh:$Refresh
    if (-not $registry.Contains($Name)) { throw [System.Management.Automation.ItemNotFoundException]::new("Workflow '$Name' is not registered.") }
    $registry[$Name]
}

function Resolve-DevWorkflowParameters {
    [CmdletBinding()]
    param([Parameter(Mandatory)] $Definition, [hashtable] $Parameter = @{})

    $declared = @{}
    foreach ($item in $Definition.Parameters) { $declared[$item.Name] = $item }
    foreach ($name in $Parameter.Keys) {
        if (-not $declared.ContainsKey($name)) { throw "Workflow '$($Definition.Name)' does not declare parameter '$name'." }
    }
    $effective = [ordered]@{}
    $arguments = [System.Collections.Generic.List[string]]::new()
    foreach ($argument in $Definition.Arguments) { $arguments.Add([string]$argument) }
    foreach ($item in $Definition.Parameters) {
        $provided = $Parameter.ContainsKey($item.Name)
        $value = if ($provided) { $Parameter[$item.Name] } else { $item.DefaultValue }
        if ($item.Required -and ($null -eq $value -or [string]::IsNullOrWhiteSpace([string]$value))) { throw "Workflow parameter '$($item.Name)' is required." }
        if ($item.Type -eq 'Switch') {
            $value = [System.Management.Automation.LanguagePrimitives]::ConvertTo($value, [bool])
            if ($value) { $arguments.Add($item.Argument) }
        }
        elseif ($null -ne $value) {
            $value = [string]$value
            if ($item.AllowedValues.Count -gt 0 -and $value -notin $item.AllowedValues) { throw "Workflow parameter '$($item.Name)' must be one of: $($item.AllowedValues -join ', ')." }
            $arguments.Add($item.Argument)
            $arguments.Add($value)
        }
        $effective[$item.Name] = if ($item.Sensitive -and $null -ne $value) { '<redacted>' } else { $value }
    }
    [pscustomobject]@{ Effective = $effective; Arguments = $arguments.ToArray() }
}

function Resolve-DevWorkflowDependencyOrder {
    [CmdletBinding()]
    param([Parameter(Mandatory)] $Definition, [Parameter(Mandatory)] $Registry)
    $ordered = [System.Collections.Generic.List[object]]::new()
    $visited = @{}; $active = @{}
    function Resolve-WorkflowDependencyNode([object] $current) {
        if ($active.ContainsKey($current.Name)) { throw "Circular workflow dependency detected at '$($current.Name)'." }
        if ($visited.ContainsKey($current.Name)) { return }
        $active[$current.Name] = $true
        foreach ($dependencyName in $current.DependsOn) {
            if (-not $Registry.Contains($dependencyName)) { throw "Workflow '$($current.Name)' depends on missing workflow '$dependencyName'." }
            Resolve-WorkflowDependencyNode $Registry[$dependencyName]
        }
        [void]$active.Remove($current.Name)
        $visited[$current.Name] = $true
        $ordered.Add($current)
    }
    Resolve-WorkflowDependencyNode $Definition
    $ordered.ToArray()
}

function Resolve-DevWorkflowExecutable {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string] $Command)
    $application = Get-Command -Name $Command -CommandType Application -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($application) { return $application.Source }
    $null
}

function New-DevWorkflowPlanInternal {
    [CmdletBinding()]
    param([Parameter(Mandatory)] $Definition, [hashtable] $Parameter = @{}, [switch] $Refresh, [AllowNull()] $Workspace)

    $started = [System.Diagnostics.Stopwatch]::StartNew()
    $registry = Initialize-DevWorkflowRegistry -Refresh:$Refresh
    $workspace = if ($Definition.RequiresWorkspace -and -not $PSBoundParameters.ContainsKey('Workspace')) { Get-Workspace -Refresh:$Refresh } else { $Workspace }
    $problems = [System.Collections.Generic.List[string]]::new()
    $workingDirectory = if ($Definition.RequiresWorkspace) { $workspace.Root } else { (Get-Location).Path }
    if ($Definition.RequiresWorkspace -and (-not $workspace.IsWorkspace -or -not $workspace.Root)) { $problems.Add("Workflow '$($Definition.Name)' requires a workspace. Run it within a discovered workspace.") }
    if ($workingDirectory -and -not (Test-Path -LiteralPath $workingDirectory -PathType Container)) { $problems.Add("Working directory '$workingDirectory' does not exist.") }
    $executable = Resolve-DevWorkflowExecutable -Command $Definition.Command
    if (-not $executable) { $problems.Add("Required executable '$($Definition.Command)' was not found.") }
    $resolvedParameters = Resolve-DevWorkflowParameters -Definition $Definition -Parameter $Parameter
    try { $dependencyOrder = @(Resolve-DevWorkflowDependencyOrder -Definition $Definition -Registry $registry | Select-Object -ExpandProperty Name) }
    catch { $problems.Add($_.Exception.Message); $dependencyOrder = @() }
    $started.Stop()
    $plan = [pscustomobject][ordered]@{
        WorkflowName=$Definition.Name; Executable=$executable; Arguments=@($resolvedParameters.Arguments)
        WorkingDirectory=$workingDirectory; Parameters=$resolvedParameters.Effective; Dependencies=@($Definition.DependsOn)
        ExecutionOrder=$dependencyOrder; TimeoutSeconds=$Definition.TimeoutSeconds; Environment=[ordered]@{}
        Allowed=($problems.Count -eq 0); Problems=$problems.ToArray(); PlanningDurationMs=[math]::Round($started.Elapsed.TotalMilliseconds,2)
    }
    $plan.PSObject.TypeNames.Insert(0, 'Aundy.DevShell.WorkflowPlan')
    $plan
}

function Limit-DevWorkflowOutput {
    [CmdletBinding()]
    param([AllowNull()][string] $Value)
    if ($null -eq $Value -or $Value.Length -le $script:DevWorkflowOutputLimit) { return $Value }
    $Value.Substring(0, $script:DevWorkflowOutputLimit) + "`n[output truncated]"
}

function Invoke-DevWorkflowProcess {
    [CmdletBinding()]
    param([Parameter(Mandatory)] $Plan)
    $start = [datetime]::UtcNow
    $watch = [System.Diagnostics.Stopwatch]::StartNew()
    $process = [System.Diagnostics.Process]::new()
    $process.StartInfo = [System.Diagnostics.ProcessStartInfo]::new()
    $process.StartInfo.FileName = $Plan.Executable
    $process.StartInfo.WorkingDirectory = $Plan.WorkingDirectory
    $process.StartInfo.UseShellExecute = $false
    $process.StartInfo.RedirectStandardOutput = $true
    $process.StartInfo.RedirectStandardError = $true
    $process.StartInfo.CreateNoWindow = $true
    foreach ($argument in $Plan.Arguments) { [void]$process.StartInfo.ArgumentList.Add([string]$argument) }
    try {
        [void]$process.Start()
        $stdoutTask = $process.StandardOutput.ReadToEndAsync()
        $stderrTask = $process.StandardError.ReadToEndAsync()
        $completed = $process.WaitForExit($Plan.TimeoutSeconds * 1000)
        if (-not $completed) {
            try { $process.Kill($true) } catch { $process.Kill() }
            $process.WaitForExit()
        }
        [System.Threading.Tasks.Task]::WaitAll(@($stdoutTask,$stderrTask))
        $watch.Stop()
        [pscustomobject]@{
            Status=if ($completed) { if ($process.ExitCode -eq 0) { 'Succeeded' } else { 'Failed' } } else { 'TimedOut' }
            Succeeded=($completed -and $process.ExitCode -eq 0); ExitCode=if ($completed) { $process.ExitCode } else { $null }
            StartedAt=$start; CompletedAt=[datetime]::UtcNow; DurationMs=[math]::Round($watch.Elapsed.TotalMilliseconds,2)
            Output=Limit-DevWorkflowOutput -Value $stdoutTask.Result; ErrorOutput=Limit-DevWorkflowOutput -Value $stderrTask.Result; Error=$null
        }
    }
    catch {
        $watch.Stop()
        [pscustomobject]@{ Status='Failed'; Succeeded=$false; ExitCode=$null; StartedAt=$start; CompletedAt=[datetime]::UtcNow
            DurationMs=[math]::Round($watch.Elapsed.TotalMilliseconds,2); Output=''; ErrorOutput=''; Error=$_.Exception.Message }
    }
    finally { $process.Dispose() }
}
