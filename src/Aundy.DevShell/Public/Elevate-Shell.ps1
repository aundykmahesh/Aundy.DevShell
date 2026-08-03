function Elevate-Shell {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseApprovedVerbs', '', Justification = 'Legacy public command retained for backward compatibility.')]
    param()

    if (!(New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        $process = @{
            FilePath = 'pwsh'
            Verb     = 'RunAs'
        }

        if ($PSVersionTable.PSVersion.Major -eq 5) {
            $process.FilePath = 'Powershell'
        }

        Start-Process @process
    }
}
