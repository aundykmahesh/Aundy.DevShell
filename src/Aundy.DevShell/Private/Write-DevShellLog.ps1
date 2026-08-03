function Write-DevShellVerbose {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string] $Message)
    Write-Verbose -Message $Message
}

function Write-DevShellInformation {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string] $Message)
    Write-Information -MessageData $Message -Tags 'Aundy.DevShell'
}

function Write-DevShellWarning {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string] $Message)
    Write-Warning -Message $Message
}

function Write-DevShellError {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string] $Message,
        [System.Management.Automation.ErrorRecord] $ErrorRecord
    )

    if ($ErrorRecord) {
        $PSCmdlet.ThrowTerminatingError($ErrorRecord)
    }

    throw $Message
}
