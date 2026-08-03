function Install-Linux {  
    @( 
        @{ Id = 'Microsoft.Wsl' }, 
        @{ Id = 'Canonical.Ubuntu' }, 
        @{ Id = 'Docker.DockerDesktop' }
    ) | ForEach-Object { Install-Package $_ } 
}
