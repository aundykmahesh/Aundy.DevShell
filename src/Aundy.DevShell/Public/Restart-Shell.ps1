function Restart-Shell {
    $shell = if ($PSVersionTable.PSVersion.Major -ge 6) { 'pwsh' } else { 'powershell' }
    Start-Process $shell -NoNewWindow
    exit
}
