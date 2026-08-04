Set-StrictMode -Version Latest

$script:ModuleImportStopwatch = [System.Diagnostics.Stopwatch]::StartNew()
$script:ModuleRoot = $PSScriptRoot
$script:Settings = Import-PowerShellDataFile -LiteralPath (Join-Path $PSScriptRoot 'Settings.psd1')
$script:DefaultWorkingDirectory = Get-Item -LiteralPath $script:Settings.WorkingDirectories.Default -ErrorAction SilentlyContinue
$script:PromptStyleOverride = $null
$script:ModuleImportMilliseconds = 0.0
$script:AzurePromptContextChecked = $false
$script:AzurePromptContext = $null

foreach ($directory in 'Context', 'Private', 'Public') {
    $scripts = Get-ChildItem -LiteralPath (Join-Path $PSScriptRoot $directory) -Filter '*.ps1' -File -ErrorAction Stop
    foreach ($scriptFile in $scripts) {
        . $scriptFile.FullName
    }
}

$promptScripts = Get-ChildItem -LiteralPath (Join-Path $PSScriptRoot 'Prompt') -Filter '*.ps1' -File -Recurse -ErrorAction Stop
foreach ($scriptFile in $promptScripts) {
    . $scriptFile.FullName
}

$publicFunctions = Get-ChildItem -LiteralPath (Join-Path $PSScriptRoot 'Public') -Filter '*.ps1' -File |
    ForEach-Object { $_.BaseName }
$publicFunctions += @(
    'Get-DevContext'
    'Get-DevShellPrompt'
    'New-DevShellPromptTheme'
    'Set-DevShellPromptStyle'
    'Show-DevContext'
)

Export-ModuleMember -Function $publicFunctions

Set-Alias -Name reload -Value Reload-Profile
Set-Alias -Name rshell -Value Restart-Shell
Set-Alias -Name .code -Value Open-Code
Set-Alias -Name .codecleanest -Value CodeCleanest
Export-ModuleMember -Alias @('reload', 'rshell', '.code', '.codecleanest')

$script:ModuleImportStopwatch.Stop()
$script:ModuleImportMilliseconds = $script:ModuleImportStopwatch.Elapsed.TotalMilliseconds
