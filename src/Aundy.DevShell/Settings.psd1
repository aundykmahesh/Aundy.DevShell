@{
    RepositoryRoot = $null
    WorkingDirectories = @{
        Default       = 'C:\Users\Mahesh\source\repos'
        CBI           = 'C:\Users\Mahesh\source\repos\CBI'
        CE            = 'C:\Users\Mahesh\source\repos\CE'
        GroupServices = 'C:\Users\Mahesh\source\repos\GroupServices'
        Payments      = 'C:\Users\Mahesh\source\repos\PaymentsDomain'
        Shared        = 'C:\Users\Mahesh\source\repos\SharedDomain'
        Tools         = 'C:\Users\Mahesh\source\repos\Tools'
    }
    Endpoints       = @{
        Ollama   = 'http://localhost:11434'
        OpenWebUI = 'http://localhost:3000'
        AIAundy  = 'http://localhost:8080'
    }
    Prompt          = @{
        Style           = 'Minimal'
        ThemePath       = '../../themes/Aundy.omp.json'
        ShowAzure       = $true
        ShowGit         = $true
        ShowTime        = $true
        ShowFolder      = $true
        ShowErrors      = $true
        TimeFormat      = '15:04'
        PromptCharacter = '❯'
        Separator       = '│'
        Symbols         = @{
            Azure  = '☁'
            Git    = ''
            Clean  = '✔'
            Dirty  = '●'
            Failed = '✖'
        }
        Colors          = @{
            Time   = '#6B7280'
            Folder = '#3B82F6'
            Git    = '#A78BFA'
            Azure  = '#22D3EE'
            Error  = '#EF4444'
            Prompt = '#22C55E'
        }
        Folder          = @{
            HomeSymbol      = '~'
            Separator       = '/'
            MaxDepth        = 2
            MappedLocations = @{
                'C:/Users/Mahesh' = '~'
                'C:/Git'          = ''
            }
        }
        AzureAliases     = @{
            'BOQ Group Non-Prod Sub 1' = 'BOQ NonProd'
        }
    }
    PreferredEditor = 'code'
    Git             = @{
        DefaultBranch = 'main'
        PullStrategy  = 'ff-only'
    }
    Logging         = @{
        EnableTranscript = $false
        TranscriptPath   = $null
    }
    Profile         = @{
        ModulePaths = @(
            'C:\Git\AI.Aundy.OS\src\AI.Aundy.Services\AI.Aundy.Services.psd1'
            'C:\Git\AI.Aundy.OS\src\AI.Aundy.Runtime\AI.Aundy.Runtime.psd1'
        )
    }
}
