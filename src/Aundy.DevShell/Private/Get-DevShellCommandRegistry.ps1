function Get-DevShellCommandRegistry {
    [CmdletBinding()]
    param()

    $definitions = @(
        ,@('Get-MachineContext', 'Machine Context', 'Returns information about the current machine.', @('Get-DevContext'), 'Internal')
        ,@('Get-DevContext', 'Developer Context', 'Returns the current developer context.', @('Show-DevContext', 'Get-MachineContext', 'Get-Workspace'))
        ,@('Show-DevContext', 'Developer Context', 'Displays a summary of the current developer context.', @('Get-DevContext', 'Show-Workspace'))
        ,@('Get-Workspace', 'Workspace', 'Returns the current developer workspace.', @('Show-Workspace', 'Get-WorkspaceRepositories', 'Get-DevContext'))
        ,@('Show-Workspace', 'Workspace', 'Displays a summary of the current workspace.', @('Get-Workspace', 'Get-WorkspaceRepositories'))
        ,@('Get-WorkspaceRepositories', 'Workspace', 'Lists repositories in the current workspace.', @('Get-Workspace', 'Open-Repository'))
        ,@('Get-WorkspaceSolutions', 'Workspace', 'Lists solutions in the current workspace.', @('Get-Workspace', 'Get-WorkspaceProjects'))
        ,@('Get-WorkspaceProjects', 'Workspace', 'Lists projects in the current workspace.', @('Get-Workspace', 'Get-WorkspaceSolutions'))
        ,@('Get-DevLocation', 'Workspace', 'Lists configured developer navigation locations.', @('Set-DevLocation', 'Get-Workspace'))
        ,@('Set-DevLocation', 'Workspace', 'Changes to a configured developer navigation location.', @('Get-DevLocation', 'Get-Workspace'))
        ,@('Get-DevShellPrompt', 'Prompt', 'Returns the rendered DevShell prompt.', @('Show-DevShellPrompt', 'Set-DevShellPromptStyle'))
        ,@('Get-DevShellPromptStyle', 'Prompt', 'Returns the active DevShell prompt style.', @('Get-DevShellPromptStyles', 'Set-DevShellPromptStyle'))
        ,@('Get-DevShellPromptStyles', 'Prompt', 'Lists available DevShell prompt styles.', @('Get-DevShellPromptStyle', 'Set-DevShellPromptStyle'))
        ,@('Show-DevShellPrompt', 'Prompt', 'Displays a preview of the DevShell prompt.', @('Get-DevShellPrompt', 'New-DevShellPromptTheme'))
        ,@('Get-DevShellPromptSettings', 'Prompt', 'Returns the effective prompt settings.', @('Set-DevShellPromptStyle'), 'Internal')
        ,@('Set-DevShellPromptStyle', 'Prompt', 'Selects the active DevShell prompt style.', @('Show-DevShellPrompt', 'New-DevShellPromptTheme'))
        ,@('New-DevShellPromptTheme', 'Prompt', 'Creates a DevShell prompt theme.', @('Set-DevShellPromptStyle', 'Show-DevShellPrompt'))
        ,@('Enable-DevShellPromptRefresh', 'Prompt', 'Enables background prompt context refresh.', @('Show-DevShellPrompt'))
        ,@('Show-DevShellDiagnostics', 'Diagnostics', 'Displays DevShell diagnostic information.', @('Get-DevShellSettings', 'Test-Administrator'))
        ,@('Clear-GitWorkspace', 'Git', 'Removes generated files from a Git workspace.', @('Clear-ProjectWorkspace', 'Reset-GitConnection'))
        ,@('Reset-GitConnection', 'Git', 'Resets the Git remote connection.', @('Clear-GitWorkspace', 'Open-Repository'))
        ,@('Start-Azurite', 'Azure', 'Starts the local Azurite storage emulator.', @('Install-AzureDeveloperTools'))
        ,@('Set-SqlServerFirewallRule', 'Azure', 'Configures an Azure SQL Server firewall rule.', @('Install-SqlServer'))
        ,@('Install-AzureDeveloperTools', 'Azure', 'Installs Azure development tools.', @('Install-DeveloperTools', 'Start-Azurite'))
        ,@('New-DockerDatabaseServer', 'Docker', 'Creates a database server in Docker.', @('Install-SqlServer'))
        ,@('Invoke-ClaudeLocal', 'AI', 'Invokes Claude through a local integration.', @('Invoke-ClaudeApi'))
        ,@('Invoke-ClaudeApi', 'AI', 'Invokes Claude through its API.', @('Invoke-ClaudeLocal'))
        ,@('Install-AIOllamaService', 'AI', 'Installs and configures Ollama as a Windows service.', @('Get-AIOllamaStatus', 'Get-AIRuntime'))
        ,@('Install-AIOpenWebUIService', 'AI', 'Installs and configures Open WebUI as a Windows service.', @('Get-AIOpenWebUIStatus', 'Get-AIRuntime'))
        ,@('Get-AICloudflareStatus', 'AI', 'Returns the status of the AI Cloudflare tunnel.', @('Get-AIRuntime'))
        ,@('Get-AIOllamaStatus', 'AI', 'Returns Ollama service and endpoint status.', @('Install-AIOllamaService', 'Get-AIRuntime'))
        ,@('Get-AIOpenWebUIStatus', 'AI', 'Returns Open WebUI service and endpoint status.', @('Install-AIOpenWebUIService', 'Get-AIRuntime'))
        ,@('Get-AIRuntime', 'AI', 'Returns the combined AI runtime status.', @('Get-AIOllamaStatus', 'Get-AIOpenWebUIStatus', 'Get-AICloudflareStatus'))
        ,@('Push-Work', 'Navigation', 'Changes location to the configured work directory.', @('Push-Folder', 'Open-Code'))
        ,@('Push-Folder', 'Navigation', 'Changes location to a selected folder.', @('Push-Work', 'Open-CurrentDirectory'))
        ,@('CBI', 'Navigation', 'Changes location to the CBI repository folder.', @('Push-Work'))
        ,@('CE', 'Navigation', 'Changes location to the CE repository folder.', @('Push-Work'))
        ,@('Common', 'Navigation', 'Changes location to the Common repository folder.', @('Push-Work'))
        ,@('DenovoBank', 'Navigation', 'Changes location to the DenovoBank repository folder.', @('Push-Work'))
        ,@('GroupServices', 'Navigation', 'Changes location to the GroupServices repository folder.', @('Push-Work'))
        ,@('PaymentsDomain', 'Navigation', 'Changes location to the PaymentsDomain repository folder.', @('Push-Work'))
        ,@('Personal', 'Navigation', 'Changes location to the Personal repository folder.', @('Push-Work'))
        ,@('ServiceFabric', 'Navigation', 'Changes location to the ServiceFabric repository folder.', @('Push-Work'))
        ,@('SharedDomain', 'Navigation', 'Changes location to the SharedDomain repository folder.', @('Push-Work'))
        ,@('Templates', 'Navigation', 'Changes location to the Templates repository folder.', @('Push-Work'))
        ,@('Tools', 'Navigation', 'Changes location to the Tools repository folder.', @('Push-Work'))
        ,@('Open-Repository', 'Navigation', 'Opens a Git repository.', @('Open-Code', 'Get-WorkspaceRepositories'))
        ,@('Open-Code', 'Navigation', 'Opens a path in Visual Studio Code.', @('Open-Repository', 'Open-CurrentDirectory'))
        ,@('Open-CurrentDirectory', 'Navigation', 'Opens the current directory in Explorer.', @('Open-Code', 'Push-Folder'))
        ,@('Backup-DevEnvironment', 'Environment', 'Backs up the developer environment configuration.', @('Install-Environment'))
        ,@('Install-Environment', 'Environment', 'Installs the configured developer environment.', @('Backup-DevEnvironment', 'Install-DeveloperTools'))
        ,@('Get-DevShellSettings', 'Environment', 'Returns the effective DevShell settings.', @('Show-DevShellDiagnostics'))
        ,@('Initialize-DevShellProfile', 'Installation', 'Initializes the PowerShell profile for DevShell.', @('Reload-Profile', 'Initialize-Themes'))
        ,@('Initialize-Themes', 'Installation', 'Installs and initializes DevShell themes.', @('Initialize-DevShellProfile'))
        ,@('Install-CodeExtensions', 'Installation', 'Installs configured Visual Studio Code extensions.', @('Install-VisualStudio'))
        ,@('Install-Communication', 'Installation', 'Installs communication applications.', @('Install-Environment'))
        ,@('Install-DeveloperTools', 'Installation', 'Installs developer tooling.', @('Install-Environment', 'Install-AzureDeveloperTools'))
        ,@('Install-Entertainment', 'Installation', 'Installs configured entertainment applications.', @('Install-Environment'))
        ,@('Install-Linux', 'Installation', 'Installs the configured Linux environment.', @('Install-Environment'))
        ,@('Install-Package', 'Installation', 'Installs a package through the configured package manager.', @('Install-Environment'))
        ,@('Install-Productivity', 'Installation', 'Installs productivity applications.', @('Install-Environment'))
        ,@('Install-SqlServer', 'Installation', 'Installs SQL Server development tooling.', @('New-DockerDatabaseServer'))
        ,@('Install-Utilities', 'Installation', 'Installs configured utility applications.', @('Install-Environment'))
        ,@('Install-VisualStudio', 'Installation', 'Installs Visual Studio.', @('Install-DeveloperTools', 'Install-CodeExtensions'))
        ,@('CodeCleanest', 'Utilities', 'Opens the CodeCleanest workspace.', @('Open-Code'))
        ,@('Connect-BoqDevVm', 'Utilities', 'Connects to the configured development virtual machine.', @('Push-Work'))
        ,@('Elevate-Shell', 'Utilities', 'Starts an elevated PowerShell session.', @('Test-Administrator'))
        ,@('Get-PublicIp', 'Utilities', 'Returns the current public IP address.', @('Show-DevShellDiagnostics'))
        ,@('Invoke-ReloadProfile', 'Utilities', 'Reloads the PowerShell profile in the current session.', @('Reload-Profile'))
        ,@('Reload-Profile', 'Utilities', 'Reloads the PowerShell profile.', @('Restart-Shell'))
        ,@('Restart-Shell', 'Utilities', 'Restarts the current shell.', @('Reload-Profile'))
        ,@('Remove-BuiltInPester', 'Utilities', 'Removes the Windows built-in Pester module.', @('Invoke-Tests'))
        ,@('Test-Administrator', 'Utilities', 'Tests whether the current session is elevated.', @('Elevate-Shell'))
        ,@('Clear-ProjectWorkspace', 'Utilities', 'Removes generated files from a project workspace.', @('Clear-GitWorkspace'))
        ,@('Invoke-Tests', 'Testing', 'Runs the DevShell test suite.', @('Show-DevShellDiagnostics'))
        ,@('Get-DevWorkflow', 'Workflow', 'Lists registered developer workflows.', @('Resolve-DevWorkflow', 'Invoke-DevWorkflow', 'Test-DevWorkflow'))
        ,@('Resolve-DevWorkflow', 'Workflow', 'Creates a validated workflow execution plan without running it.', @('Get-DevWorkflow', 'Invoke-DevWorkflow'))
        ,@('Invoke-DevWorkflow', 'Workflow', 'Invokes a registered developer workflow and returns a structured result.', @('Get-DevWorkflow', 'Resolve-DevWorkflow', 'Test-DevWorkflow'))
        ,@('Test-DevWorkflow', 'Workflow', 'Diagnoses the Developer Workflow Engine without invoking workflows.', @('Get-DevWorkflow', 'Resolve-DevWorkflow'))
        ,@('Get-DevShellCommands', 'Utilities', 'Returns the DevShell command registry.', @('Show-DevShell'))
        ,@('Test-DevShell', 'Utilities', 'Tests the availability and ownership of registered DevShell commands.', @('Get-DevShellCommands', 'Show-DevShellDiagnostics'))
        ,@('Show-DevShell', 'Utilities', 'Displays command discovery and navigation help.', @('Get-DevShellCommands'))
    )

    foreach ($definition in $definitions) {
        $visibility = 'Public'
        $relatedEndIndex = $definition.Count - 1
        if ($definition[-1] -eq 'Internal') {
            $visibility = 'Internal'
            $relatedEndIndex--
        }

        [string[]]$relatedCommands = @(
            if ($relatedEndIndex -ge 3) {
                $definition[3..$relatedEndIndex] | ForEach-Object {
                    foreach ($relatedCommand in @($_)) {
                        [string]$relatedCommand
                    }
                }
            }
        )

        [pscustomobject][ordered]@{
            Name            = $definition[0]
            Category        = $definition[1]
            Summary         = $definition[2]
            RelatedCommands = $relatedCommands
            Visibility      = $visibility
        }
    }
}
