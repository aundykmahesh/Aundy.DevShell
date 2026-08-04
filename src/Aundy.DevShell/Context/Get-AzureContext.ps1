function Get-AzureContext {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param()

    $result = [ordered]@{ AzureSubscription = $null; AzureTenant = $null; AzureEnvironment = $null }
    if (Get-Command -Name Get-AzContext -ErrorAction SilentlyContinue) {
        try {
            $context = Get-AzContext -ErrorAction Stop
            if ($context) {
                $result.AzureSubscription = $context.Subscription.Name
                $result.AzureTenant = $context.Tenant.Id
                $result.AzureEnvironment = $context.Environment.Name
                return [pscustomobject]$result
            }
        }
        catch { }
    }

    if (-not (Get-Command -Name az -ErrorAction SilentlyContinue)) { return [pscustomobject]$result }
    $json = & az account show --output json 2>$null
    if ($LASTEXITCODE -ne 0 -or -not $json) { return [pscustomobject]$result }
    $account = $json | ConvertFrom-Json -ErrorAction Stop
    $result.AzureSubscription = $account.name
    $result.AzureTenant = $account.tenantId
    $result.AzureEnvironment = $account.environmentName
    [pscustomobject]$result
}
