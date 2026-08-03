function Install-Entertainment { 
    @( 
        @{ Name = 'Netflix' }, 
        @{ Id = 'Valve.Steam' }
     ) | ForEach-Object { Install-Package $_ } 
}
