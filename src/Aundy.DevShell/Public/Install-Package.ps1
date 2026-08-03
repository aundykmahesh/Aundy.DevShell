function Install-Package {
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        $package
    )

    'Installing package {0}' -f (ConvertTo-Json $package -Compress) | Write-Verbose -Verbose
    
    if ($package.ContainsKey('Id')) {
        winget install --id $package.Id 
    } elseif ($package.ContainsKey('Name')) {
        winget install --name $package.Name
    }
}
