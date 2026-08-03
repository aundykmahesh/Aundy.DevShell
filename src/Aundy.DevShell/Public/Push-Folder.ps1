function Push-Folder {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [string]$path,

        [Parameter(Mandatory = $false)]
        [string]$childPath = $null
    )

    $folder = $path
    if ($null -ne $childPath) {
        $folder = Join-Path -Path $path -ChildPath $childPath
    }

    if (-not(Test-Path -Path $folder)) {
        New-Item -Path $folder -ItemType Directory -Force > $null
    }

    Push-Location -Path $folder
}
