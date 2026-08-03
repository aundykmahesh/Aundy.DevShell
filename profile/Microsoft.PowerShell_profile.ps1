Import-Module Aundy.DevShell -ErrorAction Stop
Initialize-DevShellProfile

$theme = New-DevShellPromptTheme
if ($theme -and (Get-Command -Name oh-my-posh -ErrorAction SilentlyContinue)) {
    oh-my-posh init pwsh --config $theme.FullName | Invoke-Expression
}
