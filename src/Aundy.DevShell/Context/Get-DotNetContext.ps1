function Get-DotNetContext {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param()

    $version = $null
    if (Get-Command -Name dotnet -ErrorAction SilentlyContinue) {
        $value = & dotnet --version 2>$null
        if ($LASTEXITCODE -eq 0) { $version = [string]($value | Select-Object -First 1) }
    }
    [pscustomobject]@{ DotNetVersion = $version }
}
