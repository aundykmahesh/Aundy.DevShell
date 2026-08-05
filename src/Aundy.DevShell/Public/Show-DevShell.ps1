function Show-DevShell {
    <#
    .SYNOPSIS
    Displays the DevShell command discovery experience.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Position = 0)]
        [string]$Query
    )

    $commands = @(Get-DevShellCommands | Where-Object Visibility -eq 'Public')

    if ([string]::IsNullOrWhiteSpace($Query)) {
        $version = (Get-Module Aundy.DevShell).Version
        $border = '=' * 57
        Write-Output $border
        Write-Output ('{0}{1}' -f (' ' * 16), "Aundy.DevShell v$version")
        Write-Output $border
        Write-Output ''

        foreach ($category in ($commands.Category | Sort-Object -Unique)) {
            Write-Output $category
            Write-Output ('-' * $category.Length)
            $commands | Where-Object Category -eq $category | ForEach-Object { Write-Output $_.Name }
            Write-Output ''
        }

        Write-Output 'Type'
        Write-Output ''
        Write-Output 'Show-DevShell <Category>'
        Write-Output ''
        Write-Output 'for more details.'
        Write-Output ''
        Write-Output 'Type'
        Write-Output ''
        Write-Output 'Get-Help <Command>'
        Write-Output ''
        Write-Output 'for command help.'
        return
    }

    $command = $commands | Where-Object Name -eq $Query | Select-Object -First 1
    if ($command) {
        Write-Output $command.Name
        Write-Output ''
        Write-Output 'Purpose'
        Write-Output ''
        Write-Output $command.Summary
        if ($command.RelatedCommands.Count -gt 0) {
            Write-Output ''
            Write-Output 'Related'
            foreach ($related in $command.RelatedCommands) {
                Write-Output ''
                Write-Output $related
            }
        }
        Write-Output ''
        Write-Output 'PowerShell Help'
        Write-Output ''
        Write-Output "Get-Help $($command.Name)"
        return
    }

    $category = $commands.Category | Where-Object { $_ -eq $Query } | Select-Object -First 1
    if ($category) {
        Write-Output $category
        Write-Output ''
        foreach ($item in ($commands | Where-Object Category -eq $category)) {
            Write-Output $item.Name
            Write-Output "    $($item.Summary)"
            Write-Output ''
        }
        return
    }

    $matches = @($commands | Where-Object {
        $_.Name -like "*$Query*" -or
        $_.Category -like "*$Query*" -or
        $_.Summary -like "*$Query*" -or
        $_.RelatedCommands -like "*$Query*"
    })

    if ($matches.Count -gt 0) {
        Write-Output "Results for '$Query'"
        Write-Output ''
        foreach ($group in ($matches | Group-Object Category | Sort-Object Name)) {
            Write-Output $group.Name
            Write-Output ('-' * $group.Name.Length)
            $group.Group | ForEach-Object { Write-Output $_.Name }
            Write-Output ''
        }
        return
    }

    Write-Warning "No DevShell category or command matches '$Query'. Run Show-DevShell to see all available commands."
}
