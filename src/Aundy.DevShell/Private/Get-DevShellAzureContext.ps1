function Get-DevShellAzureContext {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param()

    $name = $null
    $provider = $null
    try {
        if (Get-Command -Name Get-AzContext -ErrorAction SilentlyContinue) {
            $context = Get-AzContext -ErrorAction Stop
            if ($context -and $context.Subscription) {
                $name = $context.Subscription.Name
                $provider = 'Az PowerShell'
            }
        }
    }
    catch {
        $name = $null
        $provider = $null
    }

    try {
        if (-not $name -and (Get-Command -Name az -ErrorAction SilentlyContinue)) {
            $json = & az account show --output json 2>$null
            if ($LASTEXITCODE -eq 0 -and $json) {
                $account = $json | ConvertFrom-Json -ErrorAction Stop
                $name = $account.name
                $provider = 'Azure CLI'
            }
        }
    }
    catch {
        $name = $null
        $provider = $null
    }

    if (-not $name) { return $null }
    try {
        $aliases = (Get-DevShellPromptSettings).AzureAliases
        $displayName = if ($aliases.ContainsKey($name)) { $aliases[$name] } else { $name }
        [pscustomobject]@{
            Connected    = $true
            Provider     = $provider
            Subscription = $displayName
        }
    }
    catch { return $null }
}
