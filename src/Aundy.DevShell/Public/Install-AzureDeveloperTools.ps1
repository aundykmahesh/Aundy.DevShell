function Install-AzureDeveloperTools {  
    @(
        @{ Id = 'Microsoft.AzureCLI' }
        @{ Id = 'Microsoft.Azd' }
        @{ Id = 'Microsoft.Azure.StorageExplorer' }
        @{ Id = 'paolosalvatori.ServiceBusExplorer' }
        @{ Id = 'Microsoft.Azure.FunctionsCoreTools' }
        @{ Id = 'Microsoft.AzureToolsForVSCode' }
        @{ Id = 'Microsoft.Azure.SDK' }
    ) | ForEach-Object { Install-Package $_ } 
}
