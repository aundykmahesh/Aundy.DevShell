function Test-DevShell {
    <#
    .SYNOPSIS
    Tests the availability and ownership of registered DevShell commands.
    .DESCRIPTION
    Evaluates only commands returned by Get-DevShellCommands. Each registered
    command is resolved by name and compared with its expected command type and,
    when known, its expected module.

    Registry entries can optionally provide ExpectedCommandType and
    ExpectedModuleName properties. Existing registry entries remain supported;
    they default to the Function command type, and commands exported by this
    module are expected to belong to Aundy.DevShell.
    .EXAMPLE
    Test-DevShell

    Returns one health result for every registered DevShell command.
    .EXAMPLE
    Test-DevShell | Where-Object { -not $_.Healthy }

    Returns only missing commands and commands with type or module mismatches.
    .EXAMPLE
    $results = Test-DevShell
    $results | Where-Object CommandName -eq 'Get-Workspace' | Should -AllBe Healthy
    .OUTPUTS
    PSCustomObject
    #>
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param()

    $module = $ExecutionContext.SessionState.Module
    $moduleName = $module.Name
    $exportedFunctions = $module.ExportedFunctions

    foreach ($entry in @(Get-DevShellCommands)) {
        $commandName = if ($entry.PSObject.Properties['CommandName']) {
            [string]$entry.CommandName
        }
        else {
            [string]$entry.Name
        }

        $expectedCommandType = if ($entry.PSObject.Properties['ExpectedCommandType'] -and $entry.ExpectedCommandType) {
            [string]$entry.ExpectedCommandType
        }
        else {
            'Function'
        }

        $expectedModuleName = if ($entry.PSObject.Properties['ExpectedModuleName'] -and $entry.ExpectedModuleName) {
            [string]$entry.ExpectedModuleName
        }
        elseif ($entry.PSObject.Properties['ModuleName'] -and $entry.ModuleName) {
            [string]$entry.ModuleName
        }
        elseif ($exportedFunctions.ContainsKey($commandName) -or
            ($entry.PSObject.Properties['Visibility'] -and $entry.Visibility -eq 'Internal')) {
            $moduleName
        }
        else {
            $null
        }

        $resolvedCommands = @(Get-Command -Name $commandName -ErrorAction SilentlyContinue)
        $command = $resolvedCommands |
            Where-Object {
                $_ -and $_.PSObject.Properties['CommandType'] -and
                [string]$_.CommandType -eq $expectedCommandType -and
                (-not $expectedModuleName -or
                    ($_.PSObject.Properties['ModuleName'] -and $_.ModuleName -eq $expectedModuleName))
            } |
            Select-Object -First 1
        if (-not $command) {
            $command = $resolvedCommands | Select-Object -First 1
        }

        $available = $null -ne $command
        $actualCommandType = if ($available -and $command.PSObject.Properties['CommandType']) {
            [string]$command.CommandType
        }
        else {
            $null
        }
        $actualModuleName = if ($available -and $command.PSObject.Properties['ModuleName']) {
            [string]$command.ModuleName
        }
        else {
            $null
        }
        $typeMatches = $available -and $actualCommandType -eq $expectedCommandType
        $moduleMatches = $available -and (-not $expectedModuleName -or $actualModuleName -eq $expectedModuleName)
        $healthy = $available -and $typeMatches -and $moduleMatches

        $message = if (-not $available) {
            "Command '$commandName' could not be resolved."
        }
        elseif (-not $typeMatches) {
            "Expected command type '$expectedCommandType' but resolved '$actualCommandType'."
        }
        elseif (-not $moduleMatches) {
            "Expected module '$expectedModuleName' but resolved '$actualModuleName'."
        }
        else {
            'Command is available and matches its registered expectations.'
        }

        [pscustomobject][ordered]@{
            CommandName         = $commandName
            ExpectedCommandType = $expectedCommandType
            ActualCommandType   = $actualCommandType
            ExpectedModuleName  = $expectedModuleName
            ModuleName          = $actualModuleName
            Available           = $available
            Healthy             = $healthy
            Message             = $message
        }
    }
}
