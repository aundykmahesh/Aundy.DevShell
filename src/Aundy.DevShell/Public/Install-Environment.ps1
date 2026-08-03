function Install-Environment {
    Install-Utilities 
    Install-Entertainment 
    Install-Communication
    Install-Productivity
    Install-Linux
    Install-DeveloperTools
    Install-CodeExtensions
    Install-SqlServer
    Install-VisualStudio
    Install-AzureDeveloperTools

    git config --global credential.helper manager
    git config --global user.name 'Aundy'

    New-DockerDatabaseServer
}
