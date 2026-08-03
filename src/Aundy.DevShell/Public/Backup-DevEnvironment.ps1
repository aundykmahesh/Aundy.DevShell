function Backup-DevEnvironment {
    Write-Output 'Backing up the development environment.'

    try {
        Push-Folder -Path (Split-Path -Path $PSScriptRoot -Parent) -ChildPath 'Backup'

        try {
            Get-Location | Push-Folder -ChildPath 'DevEnvironment'

            try {
                Get-Location | Push-Folder -ChildPath 'vscode'
                try {
                    $settingsPath = Split-Path -Path $env:LOCALAPPDATA -Parent | Join-Path -ChildPath 'Roaming' | Join-Path -ChildPath 'Code' | Join-Path -ChildPath 'User' -AdditionalChildPath 'settings.json'
                    Write-Output "    Backing up '$($settingsPath)'"
                    Copy-Item -Path $settingsPath -Destination . > $null
                } finally {
                    Pop-Location
                }

                Get-Location | Push-Folder -ChildPath 'Work'
                try {
                    Get-ChildItem -Path $DefaultWorkingDirectory -Filter local.settings.json -Recurse | Where-Object { -not($_.FullName -Match 'Debug') } | Where-Object { -not($_.FullName -Match 'Release') } | ForEach-Object {
                        Write-Output "    Backing up '$($_.FullName)'..."

                        $path = Split-Path -Path $_.FullName -Parent
                        $path = $path.SubString($DefaultWorkingDirectory.FullName.Length + 1)

                        try {
                            Get-Location | Push-Folder -ChildPath $path
                            try {
                                Copy-Item -Path $_.FullName -Destination . > $null
                            } finally {
                                Pop-Location
                            }
                        } catch { 
                            Write-Warning "Failed to backup '$($_.FullName)'."
                        }
                    }
                } finally {
                    Pop-Location
                }

                Get-Location | Push-Folder -ChildPath 'Secrets'
                try {
                    Join-Path -Path $env:APPDATA -ChildPath 'Microsoft' | Join-Path -ChildPath 'UserSecrets' | Join-Path -ChildPath '*' | Copy-Item -Destination . -Recurse -Force
                } finally {
                    Pop-Location
                }
            } finally {
                Pop-Location
            }
        } finally {
            Pop-Location
        }
    } catch {
        Write-Warning 'An error occurred while backing up the development environment'
        Write-Warning $_.Exception.Message
    }
}
