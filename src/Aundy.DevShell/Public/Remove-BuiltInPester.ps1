function Remove-BuiltInPester {
    $module = "C:\Program Files\WindowsPowerShell\Modules\Pester"
    takeown /F $module /A /R
    icacls $module /reset
    icacls $module /grant "*S-1-5-32-544:F" /inheritance:d /T
    Remove-Item -Path $module -Recurse -Force -Confirm:$false

    Install-Module -Name Pester -Force
    Import-Module -Name Pester -PassThru
}
