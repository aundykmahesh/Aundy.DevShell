function Get-PowerShellContext {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param()

    $administrator = if ($IsWindows) {
        $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
        $principal = [Security.Principal.WindowsPrincipal]::new($identity)
        $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    }
    else { [Environment]::UserName -eq 'root' }

    [pscustomobject]@{
        PowerShellVersion  = $PSVersionTable.PSVersion.ToString()
        Administrator      = $administrator
        CurrentDirectory   = (Get-Location).Path
        CurrentUser        = [Environment]::UserName
        ComputerName       = [Environment]::MachineName
        OperatingSystem    = [System.Runtime.InteropServices.RuntimeInformation]::OSDescription
        AIRuntimeAvailable = [bool](Get-Command -Name ollama -ErrorAction SilentlyContinue)
    }
}
