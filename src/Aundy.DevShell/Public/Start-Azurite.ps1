function Start-Azurite {
    [CmdletBinding()]
    param (
        # The blob port to use. The queue and table ports are calculated of this. If 0, the default port will be used
        [Parameter(Mandatory = $false)]
        [int]$port = 0,

        # If set, will keep the previous session running (for continuing durable function testing)
        [Parameter(Mandatory = $false)]
        [switch]$keepSession
    )

    begin {
        Join-Path -Path $env:USERPROFILE -ChildPath 'AzuriteWorkingDirectory' | Set-Variable -Name 'AzuriteWorkingDirectory'

        Get-ChildItem -Path 'C:\Program Files\Microsoft Visual Studio' | Where-Object { 
            $_.Name -match '^[0-9][.]*' 
        } | Sort-Object -Property 'Name' -Descending | Select-Object -First 1 | Get-ChildItem -Filter 'azurite.exe' -Recurse | Select-Object -First 1 | Set-Variable -Name 'AzuritePath'
    }
    process {

        if ($null -eq $AzuritePath) {
            throw 'Failed to find the azurite command'
        }

        if (-not (Test-Path -Path $AzuriteWorkingDirectory)) {
            New-Item -Path $AzuriteWorkingDirectory -ItemType Directory
        }

        try {
            Push-Location -Path $AzuriteWorkingDirectory

            if (-not $keepSession) {
                Write-Information 'Clearing the previous session' -InformationAction Continue
                Get-ChildItem -Filter __azurite* | Remove-Item -Force
                Get-ChildItem -Filter __blob* | Remove-Item -Recurse -Force
                Get-ChildItem -Filter __queue* | Remove-Item -Recurse -Force
            }

            $parameters = @{
                FilePath = $azuritePath
            }

            if ($port -eq 0) {
                Write-Information "Executing $($AzuritePath.FullName)" -InformationAction Continue
            } else {
                $queuePort = $port + 1
                $tablePort = $port + 2
                $parameters.ArgumentList = @( "--blobPort $port", "--queuePort $queuePort", "--tablePort $tablePort" )
                Write-Information "Executing $($AzuritePath.FullName) `nwith the parameters`n`t--blobPort $port`n`t--queuePort $queuePort`n`t--tablePort $tablePort" -InformationAction Continue
            }

            Start-Process @parameters -NoNewWindow
        } finally {
            Pop-Location
        }
    }
}
