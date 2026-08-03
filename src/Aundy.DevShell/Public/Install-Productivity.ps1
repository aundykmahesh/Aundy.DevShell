function Install-Productivity {
    @( 
        @{ Id = 'Microsoft.Office' }
    ) | ForEach-Object { Install-Package $_ }
}
