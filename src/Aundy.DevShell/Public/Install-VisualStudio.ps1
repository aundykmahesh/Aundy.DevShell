function Install-VisualStudio {
    @(
        @{ Id = 'Microsoft.VisualStudio.2022.Professional' }
    ) | ForEach-Object { Install-Package $_ } 
}
