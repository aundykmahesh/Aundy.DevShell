function Set-SqlServerFirewallRule {

    $publicIp = Get-PublicIp

    Connect-Azure

    Get-AzSqlServer | ForEach-Object {
        $server = $_
        Get-AzSqlServerFirewallRule -ResourceGroupName $server.ResourceGroupName -ServerName $server.ServerName | Where-Object { 
            $_.FirewallRuleName -eq 'Mark@Mobile' 
        } | ForEach-Object {
            Remove-AzSqlServerFirewallRule -FirewallRuleName $_.FirewallRuleName -ResourceGroupName $server.ResourceGroupName -ServerName $server.ServerName
        }

        New-AzSqlServerFirewallRule -ResourceGroupName $server.ResourceGroupName -ServerName $server.ServerName -FirewallRuleName 'Mark@Mobile' -StartIpAddress $publicIp -EndIpAddress $publicIp
    }
}
