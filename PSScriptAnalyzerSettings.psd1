@{
    Severity     = @('Error', 'Warning')
    IncludeRules = @(
        'PSAvoidGlobalVars'
        'PSAvoidUsingCmdletAliases'
        'PSAvoidUsingWriteHost'
        'PSUseApprovedVerbs'
        'PSUseCmdletCorrectly'
        'PSUseDeclaredVarsMoreThanAssignments'
    )
    ExcludeRules = @()
}
