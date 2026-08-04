$script:MachineContextProvider = @{
    Name = 'Machine'; TimeToLive = [timespan]::FromMinutes(5); RefreshPolicy = 'OnExpiry'
    CacheKey = { 'Default' }; Command = { Get-MachineContext }
    Default = [ordered]@{ User = $null; Computer = $null; OS = $null; PowerShellVersion = $null; Administrator = $false }
}

function Get-MachineContext {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param()

    $administrator = if ($IsWindows) {
        $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
        $principal = [Security.Principal.WindowsPrincipal]::new($identity)
        $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    }
    else { [Environment]::UserName -eq 'root' }

    ConvertTo-ImmutableDevContextObject -InputObject ([ordered]@{
        User = [Environment]::UserName
        Computer = [Environment]::MachineName
        OS = [System.Runtime.InteropServices.RuntimeInformation]::OSDescription
        PowerShellVersion = $PSVersionTable.PSVersion.ToString()
        Administrator = $administrator
    })
}
