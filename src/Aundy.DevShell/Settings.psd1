@{
    RepositoryRoot = $null
    WorkingDirectories = @{ Default = '%USERPROFILE%\source\repos' }
    Navigation = @{
        Locations = @(
            @{ Name='Repos'; Path='%USERPROFILE%\source\repos'; Shortcut='repos'; Description='Source repository root'; Tags=@('source'); Enabled=$true }
            @{ Name='SharedDomain'; Path='SharedDomain'; Parent='Repos'; Shortcut='shared'; Description='SharedDomain repositories'; Tags=@('source','domain'); Enabled=$true }
            @{ Name='CBI'; Path='CBI'; Parent='Repos'; Shortcut='cbi'; Description='CBI repositories'; Tags=@('source','domain'); Enabled=$true }
            @{ Name='CE'; Path='CE'; Parent='Repos'; Shortcut='ce'; Description='CE repositories'; Tags=@('source','domain'); Enabled=$true }
            @{ Name='Common'; Path='Common'; Parent='Repos'; Description='Common repositories'; Enabled=$true }
            @{ Name='DenovoBank'; Path='DenovoBank'; Parent='Repos'; Description='DenovoBank repositories'; Enabled=$true }
            @{ Name='GroupServices'; Path='GroupServices'; Parent='Repos'; Description='GroupServices repositories'; Enabled=$true }
            @{ Name='PaymentsDomain'; Path='PaymentsDomain'; Parent='Repos'; Description='PaymentsDomain repositories'; Enabled=$true }
            @{ Name='Personal'; Path='Personal'; Parent='Repos'; Description='Personal repositories'; Enabled=$true }
            @{ Name='ServiceFabric'; Path='ServiceFabric'; Parent='Repos'; Description='Service Fabric repositories'; Enabled=$true }
            @{ Name='Templates'; Path='Templates'; Parent='Repos'; Description='Template repositories'; Enabled=$true }
            @{ Name='Tools'; Path='Tools'; Parent='Repos'; Description='Tool repositories'; Enabled=$true }
        )
    }
    Endpoints       = @{
        Ollama   = 'http://localhost:11434'
        OpenWebUI = 'http://localhost:3000'
        AIAundy  = 'http://localhost:8080'
    }
    Prompt          = @{
        Style           = 'Minimal'
        LocationDisplay = 'Repository'
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
            DotNet = '#9333EA'
            Docker = '#2496ED'
            Kubernetes = '#326CE5'
            AI = '#F59E0B'
            Administrator = '#EF4444'
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
