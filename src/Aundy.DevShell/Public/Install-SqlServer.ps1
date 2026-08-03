function Install-SqlServer {  
    @( 
        @{ Id = 'Microsoft.SQLServerManagementStudio' } 
    ) | ForEach-Object { Install-Package $_ }
}
