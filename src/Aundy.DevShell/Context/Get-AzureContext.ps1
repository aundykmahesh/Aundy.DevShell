$script:AzureContextProvider = @{
    Name = 'Azure'; TimeToLive = [timespan]::FromSeconds(30); RefreshPolicy = 'OnExpiry'
    CacheKey = { 'Default' }; Command = { Get-AzureContext }
    Default = [ordered]@{ Subscription = $null; SubscriptionId = $null; Tenant = $null; Environment = $null; Account = $null; LoggedIn = $false }
}

function Get-AzureContext {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param()

    $result = [ordered]@{ Subscription = $null; SubscriptionId = $null; Tenant = $null; Environment = $null; Account = $null; LoggedIn = $false }
    if (Get-Command -Name Get-AzContext -ErrorAction SilentlyContinue) {
        try {
            $context = Get-AzContext -ErrorAction Stop
            if ($context -and $context.Subscription) {
                $result.Subscription = $context.Subscription.Name
                $result.SubscriptionId = $context.Subscription.Id
                $result.Tenant = $context.Tenant.Id
                $result.Environment = $context.Environment.Name
                $result.Account = $context.Account.Id
                $result.LoggedIn = $true
                return ConvertTo-ImmutableDevContextObject $result
            }
        }
        catch { }
    }

    if (-not (Get-Command -Name az -ErrorAction SilentlyContinue)) { return ConvertTo-ImmutableDevContextObject $result }
    $json = & az account show --output json 2>$null
    if ($LASTEXITCODE -ne 0 -or -not $json) { return ConvertTo-ImmutableDevContextObject $result }
    $account = $json | ConvertFrom-Json -ErrorAction Stop
    $result.Subscription = $account.name
    $result.SubscriptionId = $account.id
    $result.Tenant = $account.tenantId
    $result.Environment = $account.environmentName
    $result.Account = $account.user.name
    $result.LoggedIn = $true
    ConvertTo-ImmutableDevContextObject $result
}
