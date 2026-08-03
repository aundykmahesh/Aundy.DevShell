function Install-DeveloperTools {  
    @(
        @{ Id = 'git.git' }, 
        @{ Id = 'Git.GCM' }, 
        @{ Id = 'JanDeDobbeleer.OhMyPosh' }, 
        @{ Id = 'Microsoft.VisualStudioCode' } 
    ) | ForEach-Object { Install-Package $_ } 
}
