function New-DockerDatabaseServer {
    docker run -e 'ACCEPT_EULA=Y' -e 'MSSQL_SA_PASSWORD=0mt4du0lC' -p 1433:1433 -v sqlvolume:/var/opt/mssql -d mcr.microsoft.com/mssql/server:2022-latest
}
