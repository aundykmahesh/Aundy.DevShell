function Invoke-Tests {
    [PesterConfiguration]$configuration = New-PesterConfiguration
    $configuration.Output.Verbosity = 'Detailed'
    # $configuration.Run.Exit = $true

    Invoke-Pester -Configuration $configuration
}
