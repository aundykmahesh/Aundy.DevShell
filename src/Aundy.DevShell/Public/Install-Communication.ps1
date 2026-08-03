function Install-Communication { 
    @( 
        @{ Id = 'OpenWhisperSystems.Signal' }, 
        @{ Id = 'Telegram.TelegramDesktop' }
    ) | ForEach-Object { Install-Package $_ } 
}
