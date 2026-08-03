function Install-Utilities { 
    @( 
        @{ Id = 'Microsoft.PowerToys'}, 
        @{ Id = 'AgileBits.1Password' }, 
        @{ Id = 'Wondershare.Filmora' }, 
        @{ Id = 'dotPDN.PaintDotNet' }, 
        @{ Id = '9NT1R1C2HH7J' } # ChatGpt
    ) | ForEach-Object { Install-Package $_ } 
}
