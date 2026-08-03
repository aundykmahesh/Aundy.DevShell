function Push-Work {
    param(
        # The name of the folder to find. 
        # This can be a sub folder of a company folder
        [Parameter(Mandatory=$false)]
        [string[]]$path = $null
    )

    $workFolder = $DefaultWorkingDirectory

    if (-not [string]::IsNullOrWhitespace($path)) {
        $path | ForEach-Object {
            $workFolder = Get-ChildItem -Path $workFolder -Filter $_ -Recurse | Select-Object -First 1
        }
    }

    $sourceFolder = Get-ChildItem -Path $workFolder.FullName -Filter Source

    if ($null -ne $sourceFolder) {
        Push-Location -Path $sourceFolder.FullName
    } else {
        Push-Location -Path $workFolder.FullName
    }
}
