function Get-DevContext {
    <#
    .SYNOPSIS
    Returns an immutable, provider-based snapshot of the developer environment.
    #>
    [CmdletBinding()]
    param([switch] $Refresh)

    $context = [ordered]@{}
    $providers = @(
        $script:PowerShellContextProvider
        $script:GitContextProvider
        $script:WorkspaceContextProvider
        $script:AzureContextProvider
        $script:DotNetContextProvider
        $script:DockerContextProvider
        $script:KubernetesContextProvider
        $script:AIContextProvider
        $script:MachineContextProvider
    )
    foreach ($registration in $providers) {
        $context[$registration.Name] = Invoke-DevContextProvider -Registration $registration -ForceRefresh:$Refresh
    }
    ConvertTo-ImmutableDevContextObject -InputObject $context
}
