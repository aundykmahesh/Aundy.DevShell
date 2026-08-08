$script:DevLocationRegistry = $null
$script:DevLocationRegistrySignature = $null
$script:DevLocationRegistryCacheHits = 0

function Get-DevLocationProperty {
    [CmdletBinding()]
    param([Parameter(Mandatory)] $InputObject, [Parameter(Mandatory)][string] $Name, [AllowNull()] $DefaultValue = $null)
    if ($InputObject -is [System.Collections.IDictionary]) {
        if ($InputObject.Contains($Name)) { return $InputObject[$Name] }
        return $DefaultValue
    }
    $property = $InputObject.PSObject.Properties[$Name]
    if ($property) { return $property.Value }
    $DefaultValue
}

function Expand-DevLocationPath {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string] $Path)

    $expanded = [Environment]::ExpandEnvironmentVariables($Path)
    if ($expanded -match '%[^%]+%') { throw "Location path '$Path' contains an unresolved environment variable." }
    if ([string]::IsNullOrWhiteSpace($expanded)) { throw 'Location path resolved to an empty value.' }
    $expanded
}

function Get-DevLocationSettingsSignature {
    [CmdletBinding()]
    param([Parameter(Mandatory)] $Locations)

    $parts = foreach ($location in @($Locations)) {
        '{0}|{1}|{2}|{3}|{4}' -f (Get-DevLocationProperty $location Name), (Get-DevLocationProperty $location Path), (Get-DevLocationProperty $location Parent), (Get-DevLocationProperty $location Shortcut), (Get-DevLocationProperty $location Enabled $true)
    }
    '{0}|{1}' -f ([Environment]::GetEnvironmentVariable('USERPROFILE')), ($parts -join ';')
}

function Initialize-DevLocationRegistry {
    [CmdletBinding()]
    param([switch] $Refresh, [AllowNull()] $Settings)

    if ($null -eq $Settings) { $Settings = Get-Settings }
    $definitions = @($Settings.Navigation.Locations)
    if ($definitions.Count -eq 0) { throw 'No developer navigation locations are configured in Settings.psd1.' }
    $signature = Get-DevLocationSettingsSignature -Locations $definitions
    if ($script:DevLocationRegistry -and -not $Refresh -and $script:DevLocationRegistrySignature -eq $signature) {
        $script:DevLocationRegistryCacheHits++
        return $script:DevLocationRegistry
    }

    $raw = [ordered]@{}
    $shortcuts = @{}
    foreach ($definition in $definitions) {
        $name = [string](Get-DevLocationProperty $definition Name)
        if ([string]::IsNullOrWhiteSpace($name)) { throw 'Every developer location requires a Name.' }
        if ($raw.Contains($name)) { throw "Duplicate developer location name '$name'." }
        $shortcut = [string](Get-DevLocationProperty $definition Shortcut)
        if ($shortcut) {
            if ($shortcut -notmatch '^[A-Za-z][A-Za-z0-9_-]*$') { throw "Developer location '$name' has invalid shortcut '$shortcut'." }
            if ($shortcuts.ContainsKey($shortcut)) { throw "Duplicate developer location shortcut '$shortcut'." }
            $shortcuts[$shortcut] = $name
        }
        $raw[$name] = $definition
    }

    $resolved = [ordered]@{}
    $active = @{}
    function Resolve-DevLocationDefinition([string] $Name) {
        if ($resolved.Contains($Name)) { return $resolved[$Name] }
        if (-not $raw.Contains($Name)) { throw "Unknown parent developer location '$Name'." }
        if ($active.ContainsKey($Name)) { throw "Circular developer location parent relationship detected at '$Name'." }
        $active[$Name] = $true
        $definition = $raw[$Name]
        $configuredPath = [string](Get-DevLocationProperty $definition Path)
        if ([string]::IsNullOrWhiteSpace($configuredPath)) { throw "Developer location '$Name' requires a Path." }
        $parentName = [string](Get-DevLocationProperty $definition Parent)
        if ($parentName) {
            $parent = Resolve-DevLocationDefinition -Name $parentName
            $expandedPath = Expand-DevLocationPath -Path $configuredPath
            $path = if ([System.IO.Path]::IsPathRooted($expandedPath)) { [System.IO.Path]::GetFullPath($expandedPath) } else { [System.IO.Path]::GetFullPath((Join-Path $parent.Path $expandedPath)) }
            $parentPrefix = $parent.Path.TrimEnd([System.IO.Path]::DirectorySeparatorChar, [System.IO.Path]::AltDirectorySeparatorChar) + [System.IO.Path]::DirectorySeparatorChar
            if (-not $path.StartsWith($parentPrefix, [System.StringComparison]::OrdinalIgnoreCase)) { throw "Developer location '$Name' resolves outside parent '$parentName'." }
        }
        else {
            $expandedPath = Expand-DevLocationPath -Path $configuredPath
            if (-not [System.IO.Path]::IsPathRooted($expandedPath)) { throw "Root developer location '$Name' must resolve to an absolute provider path." }
            $path = [System.IO.Path]::GetFullPath($expandedPath)
        }
        [void]$active.Remove($Name)
        $displayName = [string](Get-DevLocationProperty $definition DisplayName)
        $description = [string](Get-DevLocationProperty $definition Description)
        $definitionShortcut = [string](Get-DevLocationProperty $definition Shortcut)
        $enabled = Get-DevLocationProperty $definition Enabled $true
        $location = [pscustomobject][ordered]@{
            Name=$Name; DisplayName=if ($displayName) { $displayName } else { $Name }
            Path=$path; Parent=if ($parentName) { $parentName } else { $null }; Shortcut=if ($definitionShortcut) { $definitionShortcut } else { $null }
            Description=if ($description) { $description } else { $null }
            Tags=@(Get-DevLocationProperty $definition Tags @()); Enabled=[bool]$enabled
        }
        $location.PSObject.TypeNames.Insert(0, 'Aundy.DevShell.DevLocation')
        $resolved[$Name] = $location
        $location
    }
    foreach ($name in @($raw.Keys)) { [void](Resolve-DevLocationDefinition -Name $name) }
    $script:DevLocationRegistry = $resolved
    $script:DevLocationRegistrySignature = $signature
    $script:DevLocationRegistryCacheHits = 0
    $resolved
}

function Get-DevLocationInternal {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string] $Name, [switch] $Refresh, [AllowNull()] $Settings)
    $registry = Initialize-DevLocationRegistry -Refresh:$Refresh -Settings $Settings
    if (-not $registry.Contains($Name)) { throw [System.Management.Automation.ItemNotFoundException]::new("Developer location '$Name' is not configured.") }
    $location = $registry[$Name]
    if (-not $location.Enabled) { throw "Developer location '$($location.Name)' is disabled in Settings.psd1." }
    $location
}
